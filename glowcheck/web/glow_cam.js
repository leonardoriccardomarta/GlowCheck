window.GlowCam = {
  stream: null,
  start: async function (videoEl) {
    if (this.stream) {
      this.stop();
    }
    var stream = await navigator.mediaDevices.getUserMedia({
      audio: false,
      video: {
        facingMode: { ideal: 'environment' },
        width: { ideal: 1280 },
        height: { ideal: 720 },
      },
    });
    this.stream = stream;
    videoEl.srcObject = stream;
    videoEl.muted = true;
    videoEl.setAttribute('playsinline', 'true');
    videoEl.setAttribute('autoplay', 'true');
    await videoEl.play();
    return true;
  },
  capture: function (videoEl) {
    var w = videoEl.videoWidth || 1280;
    var h = videoEl.videoHeight || 720;
    var canvas = document.createElement('canvas');
    canvas.width = w;
    canvas.height = h;
    canvas.getContext('2d').drawImage(videoEl, 0, 0, w, h);
    return canvas.toDataURL('image/jpeg', 0.72);
  },
  stop: function () {
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
