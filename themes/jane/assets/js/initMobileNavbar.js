/**
 * mobile Navbar - pure CSS/JS implementation (no Slideout dependency)
 */
const initMobileNavbar = () => {
  const mobileNav = document.getElementById('mobile-navbar');
  const mobileNavIcon = document.querySelector('.mobile-navbar-icon');
  const mobilePanel = document.getElementById('mobile-panel');
  const mobileMenu = document.getElementById('mobile-menu');

  if (!mobileNav || !mobileNavIcon || !mobilePanel || !mobileMenu) {
    return;
  }

  let isOpen = false;

  const open = () => {
    isOpen = true;
    mobilePanel.classList.add('slideout-open');
    mobileMenu.classList.add('slideout-open');
    mobileNav.classList.add('fixed-open');
    mobileNavIcon.classList.add('icon-click');
    mobileNavIcon.classList.remove('icon-out');
  };

  const close = () => {
    isOpen = false;
    mobilePanel.classList.remove('slideout-open');
    mobileMenu.classList.remove('slideout-open');
    mobileNav.classList.remove('fixed-open');
    mobileNavIcon.classList.add('icon-out');
    mobileNavIcon.classList.remove('icon-click');
  };

  const toggle = () => {
    if (isOpen) {
      close();
    } else {
      open();
    }
  };

  mobileNavIcon.addEventListener('click', toggle);

  // close menu when clicking on the panel (content area)
  mobilePanel.addEventListener('click', (e) => {
    if (isOpen && e.target === mobilePanel) {
      close();
    }
  });

  // close menu on touch outside
  mobilePanel.addEventListener('touchend', (e) => {
    if (isOpen) {
      close();
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
        allSubmenus.forEach(menu => {
          menu.style.display = 'none';
        });
        allParents.forEach(p => {
          p.classList.remove('mobile-submenu-show');
        });
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
