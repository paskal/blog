/**
 * mobile Navbar
 */
const initMobileNavbar = () => {
  const mobileNav = document.getElementById('mobile-navbar');
  const mobileNavIcon = document.querySelector('.mobile-navbar-icon');
  const mobilePanel = document.getElementById('mobile-panel');
  const mobileMenu = document.getElementById('mobile-menu');

  if (!mobileNav || !mobileNavIcon || !mobilePanel || !mobileMenu) {
    return;
  }

  const slideout = new Slideout({
    'panel': mobilePanel,
    'menu': mobileMenu,
    'padding': 180,
    'tolerance': 70
  });
  slideout.disableTouch();

  mobileNavIcon.addEventListener('click', () => {
    slideout.toggle();
  });

  slideout.on('beforeopen', () => {
    mobileNav.classList.add('fixed-open');
    mobileNavIcon.classList.add('icon-click');
    mobileNavIcon.classList.remove('icon-out');
  });

  slideout.on('beforeclose', () => {
    mobileNav.classList.remove('fixed-open');
    mobileNavIcon.classList.add('icon-out');
    mobileNavIcon.classList.remove('icon-click');
  });

  mobilePanel.addEventListener('touchend', () => {
    if (slideout.isOpen()) {
      mobileNavIcon.click();
    }
  });

  // mobile submenu toggle
  document.querySelectorAll('.mobile-submenu-open').forEach(btn => {
    btn.addEventListener('click', function() {
      const parent = this.parentElement;
      const submenu = parent.nextElementSibling;
      const allSubmenus = document.querySelectorAll('.mobile-submenu-list');
      const allParents = document.querySelectorAll('.mobile-menu-parent');

      if (submenu && submenu.style.display !== 'block') {
        // close all submenus
        allSubmenus.forEach(menu => {
          menu.style.display = 'none';
        });
        allParents.forEach(p => {
          p.classList.remove('mobile-submenu-show');
        });
        // open this one
        submenu.style.display = 'block';
        parent.classList.add('mobile-submenu-show');
      } else if (submenu) {
        submenu.style.display = 'none';
        parent.classList.remove('mobile-submenu-show');
      }
    });
  });
};

export default initMobileNavbar
