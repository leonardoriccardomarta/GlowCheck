window.GlowCam = {
  stream: null,
  lastBarcode: '',
  _huntTimer: null,
  _detector: null,
  _hunting: false,
  FRAME: { x: 0.08, y: 0.38, w: 0.84, h: 0.22 },

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
        formats: ['ean_13', 'ean_8', 'upc_a', 'upc_e', 'code_128'],
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

  _coverRect: function (videoEl) {
    var vw = videoEl.videoWidth || 0;
    var vh = videoEl.videoHeight || 0;
    var dw = videoEl.clientWidth || 1;
    var dh = videoEl.clientHeight || 1;
    if (vw < 8 || vh < 8) return null;
    var scale = Math.max(dw / vw, dh / vh);
    return {
      sx: (vw * scale - dw) / 2 / scale,
      sy: (vh * scale - dh) / 2 / scale,
      sw: dw / scale,
      sh: dh / scale,
    };
  },

  _crop: function (from, sx, sy, sw, sh) {
    if (sw < 24 || sh < 24) return null;
    var canvas = document.createElement('canvas');
    canvas.width = Math.max(1, Math.round(sw));
    canvas.height = Math.max(1, Math.round(sh));
    canvas.getContext('2d').drawImage(from, sx, sy, sw, sh, 0, 0, canvas.width, canvas.height);
    return canvas;
  },

  _visibleCanvas: function (videoEl) {
    var r = this._coverRect(videoEl);
    if (!r) return null;
    return this._crop(videoEl, r.sx, r.sy, r.sw, r.sh);
  },

  _frameCanvas: function (videoEl) {
    var vis = this._visibleCanvas(videoEl);
    if (!vis) return null;
    var f = this.FRAME;
    var padX = vis.width * 0.03;
    var padY = vis.height * 0.06;
    var x = vis.width * f.x - padX;
    var y = vis.height * f.y - padY;
    var w = vis.width * f.w + padX * 2;
    var h = vis.height * f.h + padY * 2;
    x = Math.max(0, x);
    y = Math.max(0, y);
    w = Math.min(vis.width - x, w);
    h = Math.min(vis.height - y, h);
    return this._crop(vis, x, y, w, h);
  },

  _scanSource: async function (source) {
    if (!source) return '';
    var hit = await this._detect(source);
    if (hit) return hit;
    return '';
  },

  _huntTick: async function (videoEl) {
    if (this._hunting || !videoEl || videoEl.readyState < 2) return;
    this._hunting = true;
    try {
      var hit = await this._scanSource(this._frameCanvas(videoEl));
      if (!hit) hit = await this._scanSource(this._visibleCanvas(videoEl));
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
    }, 240);
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
    var vis = this._visibleCanvas(videoEl);
    var frame = this._frameCanvas(videoEl);
    var hit = await this._scanSource(frame);
    if (!hit) hit = await this._scanSource(vis);
    if (hit) this.lastBarcode = hit;
    var out = vis || frame;
    if (!out) {
      var fallback = document.createElement('canvas');
      fallback.width = videoEl.videoWidth || 1280;
      fallback.height = videoEl.videoHeight || 720;
      fallback.getContext('2d').drawImage(videoEl, 0, 0);
      out = fallback;
    }
    return out.toDataURL('image/jpeg', 0.92);
  },

  readBarcode: async function (videoEl) {
    var live = await this._scanSource(this._frameCanvas(videoEl));
    if (!live) live = await this._scanSource(this._visibleCanvas(videoEl));
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
