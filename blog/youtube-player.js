// Contact the external video service only after the reader chooses to load it.
for (const frame of document.querySelectorAll('[data-youtube-id]')) {
  frame.querySelector('button')?.addEventListener('click', () => {
    const id = frame.dataset.youtubeId;
    if (!/^[A-Za-z0-9_-]{11}$/.test(id || '')) return;
    const player = document.createElement('iframe');
    player.src = `https://www.youtube-nocookie.com/embed/${id}?autoplay=1`;
    player.title = frame.dataset.youtubeTitle || 'Patch PHP, then prove WordPress still works';
    player.allow = 'autoplay; encrypted-media; picture-in-picture; fullscreen';
    player.allowFullscreen = true;
    player.referrerPolicy = 'strict-origin-when-cross-origin';
    frame.replaceChildren(player);
    player.focus();
  }, { once: true });
}
