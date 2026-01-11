import initMobileNavbar from './initMobileNavbar';
import initToc from './initToc';
import initHeaderAnchor from './initHeaderAnchor';

/* main */
document.addEventListener('DOMContentLoaded', () => {
  initMobileNavbar();
  initToc();
  initHeaderAnchor();
});
