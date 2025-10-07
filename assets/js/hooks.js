let Hooks = {}

Hooks.AudioReload = {
  mounted() {
    this.reloadAudio()
  },
  updated() {
    this.reloadAudio()
  },
  reloadAudio() {
    let audio = this.el
    audio.pause()
    audio.load()
    audio.play().catch(() => {
      // play() may fail if autoplay not allowed, just ignore or handle error here
    })
  }
}

export default Hooks
