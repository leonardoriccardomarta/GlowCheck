window.GlowCam = {
  stream: null,
  lastBarcode: '',
  _huntTimer: null,
  _detector: null,
  _hunting: false,

  _gtinOk: function (raw) {
    var d = String(raw || '').replace(/\D/g, '');
    if (d.length === 12) d = '0' + d;
    if ([8, 13, 14].indexOf(d.length) === -1) return '';
    var body = d.slice(0, -1);
    var check = Number(d.slice(-1));
    var sum = 0;
    for (var i = 0; i < body.length; i++) {
      var digit = Number(body.charAt(body.length - 1 - i));
      sum += i % 2 === 0 ? digit * 3 : digit;
    }
    if ((10 - (sum % 10)) % 10 !== check) return '';
    return d;
  },

  _detectorSafe: function () {
    if (typeof BarcodeDetector === 'undefined') return null;
    if (this._detector) return this._detector;
    try {
      this._detector = new BarcodeDetector({
        formats: ['ean_13', 'ean_8', 'upc_a', 'upc_e', 'code_128', 'qr_code'],
      });
    } catch (e) {
      this._detector = null;
    }
    return this._detector;
  },

  _pickDigits: function (codes) {
    if (!codes || !codes.length) return '';
    for (var i = 0; i < codes.length; i++) {
      var ok = this._gtinOk(codes[i].rawValue);
      if (ok) return ok;
    }
    return '';
  },

  _detect: async function (source) {
    var detector = this._detectorSafe();
    if (!detector || !source) return '';
    try {
      return this._pickDigits(await detector.detect(source));
    } catch (e) {
      return '';
    }
  },

  _bandCanvas: function (from, yRatio, hRatio) {
    var w = from.width || from.videoWidth || 0;
    var h = from.height || from.videoHeight || 0;
    if (w < 40 || h < 40) return null;
    var by = Math.round(h * yRatio);
    var bh = Math.max(48, Math.round(h * hRatio));
    if (by + bh > h) by = Math.max(0, h - bh);
    var band = document.createElement('canvas');
    band.width = w;
    band.height = bh;
    band.getContext('2d').drawImage(from, 0, by, w, bh, 0, 0, w, bh);
    return band;
  },

  _scanSource: async function (source) {
    var hit = await this._detect(source);
    if (hit) return hit;
    var mid = this._bandCanvas(source, 0.28, 0.44);
    if (mid) {
      hit = await this._detect(mid);
      if (hit) return hit;
    }
    var bottom = this._bandCanvas(source, 0.5, 0.48);
    if (bottom) {
      hit = await this._detect(bottom);
      if (hit) return hit;
    }
    return '';
  },

  _huntTick: async function (videoEl) {
    if (this._hunting || !videoEl || videoEl.readyState < 2) return;
    this._hunting = true;
    try {
      var hit = await this._scanSource(videoEl);
      if (hit) this.lastBarcode = hit;
    } finally {
      this._hunting = false;
    }
  },

  _startHunt: function (videoEl) {
    var self = this;
    this._stopHunt();
    this._huntTimer = setInterval(function () {
      self._huntTick(videoEl);
    }, 280);
    this._huntTick(videoEl);
  },

  _stopHunt: function () {
    if (this._huntTimer) {
      clearInterval(this._huntTimer);
      this._huntTimer = null;
    }
    this._hunting = false;
  },

  start: async function (videoEl) {
    if (this.stream) {
      this.stop();
    }
    this.lastBarcode = '';
    var stream = await navigator.mediaDevices.getUserMedia({
      audio: false,
      video: {
        facingMode: { ideal: 'environment' },
        width: { ideal: 1920 },
        height: { ideal: 1080 },
      },
    });
    this.stream = stream;
    videoEl.srcObject = stream;
    videoEl.muted = true;
    videoEl.setAttribute('playsinline', 'true');
    videoEl.setAttribute('autoplay', 'true');
    await videoEl.play();
    try {
      var track = stream.getVideoTracks()[0];
      if (track) await track.applyConstraints({ advanced: [{ focusMode: 'continuous' }] });
    } catch (e) {}
    this._startHunt(videoEl);
    return true;
  },

  getBarcode: function () {
    return this.lastBarcode || '';
  },

  capture: async function (videoEl) {
    var w = videoEl.videoWidth || 1280;
    var h = videoEl.videoHeight || 720;
    var canvas = document.createElement('canvas');
    canvas.width = w;
    canvas.height = h;
    canvas.getContext('2d').drawImage(videoEl, 0, 0, w, h);
    var fromShot = await this._scanSource(canvas);
    if (fromShot) this.lastBarcode = fromShot;
    return canvas.toDataURL('image/jpeg', 0.84);
  },

  readBarcode: async function (videoEl) {
    var live = await this._scanSource(videoEl);
    if (live) this.lastBarcode = live;
    return this.lastBarcode || '';
  },

  stop: function () {
    this._stopHunt();
    this.lastBarcode = '';
    if (!this.stream) return;
    this.stream.getTracks().forEach(function (track) { track.stop(); });
    this.stream = null;
  },

  torch: async function (on) {
    if (!this.stream) return false;
    var track = this.stream.getVideoTracks()[0];
    if (!track) return false;
    try {
      await track.applyConstraints({ advanced: [{ torch: !!on }] });
      return true;
    } catch (e) {
      return false;
    }
  },
};
