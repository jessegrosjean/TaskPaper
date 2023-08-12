import Cocoa

extension NSMenu {
    func item(withAction action: Selector) -> NSMenuItem? {
        for each in items {
            if each.action == action {
                return each
            }
        }
        return nil
    }

    func submenuItem(withAction action: Selector) -> NSMenuItem? {
        for each in items {
            if each.action == action {
                return each
            }
            if each.hasSubmenu {
                if let item = each.submenu?.submenuItem(withAction: action) {
                    return item
                }
            }
        }
        return nil
    }
}
