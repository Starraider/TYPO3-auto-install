// =============================================================================
// Project JavaScript
// Mobile Navigation Toggle & Accessibility Handlers
// =============================================================================

document.addEventListener('DOMContentLoaded', () => {
    const toggleBtn = document.querySelector('.site-header__toggle');
    const nav = document.querySelector('.site-nav');

    if (toggleBtn && nav) {
        toggleBtn.addEventListener('click', () => {
            const isExpanded = toggleBtn.getAttribute('aria-expanded') === 'true';
            toggleBtn.setAttribute('aria-expanded', String(!isExpanded));
            toggleBtn.classList.toggle('site-header__toggle--active', !isExpanded);
            nav.classList.toggle('site-nav--open', !isExpanded);
        });

        // Close mobile nav on escape key press
        document.addEventListener('keydown', (event) => {
            if (event.key === 'Escape' && nav.classList.contains('site-nav--open')) {
                toggleBtn.setAttribute('aria-expanded', 'false');
                toggleBtn.classList.remove('site-header__toggle--active');
                nav.classList.remove('site-nav--open');
                toggleBtn.focus();
            }
        });
    }
});
