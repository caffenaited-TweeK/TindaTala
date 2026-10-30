# TindaTala --- Flutter App Design

## 1. App Overview

**App name:** TindaTala\
**Purpose:** A simple inventory-management app for Filipino sari-sari
store owners.

TindaTala helps store owners record products, check available
quantities, find low-stock items, monitor expiration dates, and record
sales so stock counts stay updated.

**Design direction:** Friendly, practical, Filipino-inspired, and easy
for beginners to understand.

## 2. Visual Identity

Use the TindaTala logo as the app's visual reference: - A warm,
hand-drawn sari-sari store badge. - A striped red-and-cream awning,
shelves of colorful goods, a small inventory checklist, and a star
detail. - A handmade, textured illustration style rather than a glossy
corporate look.

### Color palette

  Role                  Color                   Hex
  --------------------- ----------------------- -----------
  Primary               Warm brick red          `#C9432F`
  Secondary             Deep store-sign brown   `#4A281B`
  Accent                Golden yellow           `#F4B83F`
  Background            Warm cream              `#FFF8E9`
  Surface / cards       Soft ivory              `#FFFCF5`
  Success / in stock    Leaf green              `#397A4A`
  Warning / low stock   Amber                   `#D98A16`
  Expired / error       Muted red               `#B8322A`
  Supporting blue       Muted blue              `#397CA5`

Use brown for main text, cream backgrounds, and red for primary actions.
Reserve green, amber, and red status colors for inventory conditions.
Keep the red-and-cream store awning at the top of the loading and sign-in
screens.

### Typography

-   Use **Nunito** or **Nunito Sans** for a rounded, friendly feel.
-   Use bold weights for page titles, product names, and totals.
-   Keep body text simple and readable.
-   Avoid decorative fonts for small text.

### Shape and illustration

-   Cards: rounded corners (14--18 px).
-   Buttons: rounded corners (12--14 px).
-   Use clear icons with labels.
-   Keep small hand-drawn accents limited to the welcome screen, empty
    states, and branding so everyday inventory screens remain easy to
    scan.

## 3. Navigation Structure

Use a bottom navigation bar with four main destinations:

1.  **Home** --- summary and important alerts.
2.  **Inventory** --- product list, search, filters, and product
    actions.
3.  **Sales** --- record a sale and view recent sales.
4.  **More** --- categories and app settings.

The Add Product action should be easy to find from Home and Inventory,
using a prominent `+ Add Product` button.

## 4. Main Screens

### A. Welcome / Home Dashboard

**Header** - TindaTala logo or app name. - Friendly greeting such as
"Welcome to TindaTala".

**Summary cards** - Total products. - Low-stock products. - Products
nearing expiration. - Products already expired.

**Quick actions** - `+ Add Product` - `Record Sale` - `View Inventory`

**Alerts section** - Show low-stock and expiration alerts in separate,
clearly labeled cards. - Tapping an alert opens the relevant filtered
inventory list.

Keep the dashboard uncluttered. Avoid adding advanced charts unless they
are needed later.

### B. Inventory Screen

**Top area** - Page title: "Inventory" - Search field with placeholder:
"Search products..." - Filter chips: `All`, `Low Stock`,
`Near Expiration`, `Expired`

**Product list item** - Product name. - Category. - Price. - Quantity
remaining. - Expiration date, when applicable. - A small status label
such as `In Stock`, `Low Stock`, `Near Expiration`, or `Expired`.

**Actions** - Tap a product to view its details. - Provide clear `Edit`
and `Delete` actions. - Include an obvious `+ Add Product` button.

Use a list layout rather than a crowded grid because owners may need to
scan many products quickly.

### C. Add / Edit Product Screen

Use one form for both adding and editing products.

**Fields** - Product name --- required. - Price --- required, must be
zero or greater. - Quantity --- required, whole number of zero or
greater. - Category --- optional or selected from a simple list. -
Expiration date --- optional; use a date picker.

**Buttons** - `Save Product` - `Cancel`

**Validation** - Show a helpful message when a required field is missing
or invalid. - Do not save negative prices or quantities. - Ask for
confirmation before discarding unsaved changes.

### D. Product Details Screen

Show: - Product name and category. - Price and current quantity. -
Expiration date, if recorded. - Current stock status. - Actions:
`Edit Product`, `Record Sale`, and `Delete Product`.

Ask for confirmation before deleting a product.

### E. Record Sale Screen

Allow the user to: 1. Search for and select a product. 2. Enter the
quantity sold. 3. Review the product name, price, quantity available,
and sale subtotal. 4. Tap `Confirm Sale`.

**Stock rules** - Automatically subtract the sold quantity from
inventory after a valid sale is confirmed. - Do not allow a sale
quantity of zero or less. - Do not allow a sale quantity greater than
the available quantity. - Show a clear message if there is not enough
stock. - Update the inventory immediately after a successful sale.

Show a brief success message after the sale is recorded.

### F. Low-Stock and Expiration Alerts

**Low stock** - Mark a product as low stock when its quantity reaches
the configured threshold. - Use a simple default threshold, such as 5
units, and allow it to be adjusted later if needed.

**Expiration status** - `Near Expiration`: the product is within a
chosen warning period before its expiration date. - `Expired`: the
expiration date is earlier than the current date. - Products without an
expiration date should not show an expiration status.

Use both a text label and color so the status is not communicated by
color alone.

### G. More Screen

Keep this screen simple: - Manage categories. - Set low-stock
threshold. - Set expiration-warning period. - About TindaTala. -
Optional data backup/export in a future version.

Allow each store to add an optional shop photo. Show simple illustrated
category stickers when a product has no uploaded photo.

## 5. Suggested User Flow

### Add a product

Home → Add Product → Enter product details → Save Product → Inventory

### Record a sale

Sales → Select product → Enter quantity sold → Confirm Sale → Inventory
quantity updates

### Check an alert

Home → Tap Low-Stock or Expiration Alert → Review filtered products →
Edit product or restock outside the app

## 6. Reusable Flutter UI Components

Build reusable widgets to keep the app consistent:

-   `TindaTalaAppBar`
-   `SummaryCard`
-   `InventoryProductTile`
-   `StockStatusChip`
-   `AlertCard`
-   `PrimaryButton`
-   `FormTextField`
-   `EmptyState`
-   `ConfirmDeleteDialog`

Keep spacing, colors, border radii, and text styles in a shared theme
rather than defining them separately on every screen.

## 7. Flutter Implementation Notes

-   Use Flutter's Material 3 components, customized with the TindaTala
    color palette and rounded shapes.
-   Define a central `ThemeData` with a `ColorScheme`, text theme, input
    decoration theme, and button themes.
-   Use `NavigationBar` for the bottom navigation.
-   Use `ListView.builder` for inventory lists.
-   Use `TextFormField` and a `Form` for product forms.
-   Use Flutter's date picker for expiration dates.
-   Keep UI, data models, and inventory logic separate.
-   Create a `Product` model containing an ID, name, price, quantity,
    category, and optional expiration date.
-   Store sales as separate records containing the product ID, quantity
    sold, unit price at the time of sale, total, and sale date.
-   For a beginner-friendly first version, choose a simple local
    persistence solution. If the app needs to run across multiple
    devices or users later, evaluate a database or backend at that
    stage.
-   Keep each account's products, sales, settings, and image references
    separate on the device.
-   Calculate stock status from the current quantity and threshold
    rather than manually maintaining duplicate status values.
-   Keep sale recording and stock deduction consistent so a sale cannot
    be counted without updating inventory.

## 8. Accessibility and Usability

-   Use readable text and strong contrast.
-   Make tap targets comfortably large.
-   Give icons accessible labels.
-   Do not rely on color alone for low-stock or expiration status.
-   Show helpful empty states, for example: "No products yet. Add your
    first product to get started."
-   Use simple, familiar wording suitable for store owners who may not
    be tech-savvy.

## 9. MVP Scope

Build these features first: 1. Add, view, edit, and delete products. 2.
Search products. 3. Record sales and automatically update stock. 4.
Low-stock alerts. 5. Expiration-date tracking and warnings.

Avoid adding customer accounts, supplier management, online payments,
advanced analytics, or multi-branch support to the first version. These
can be considered only if the basic app works well.

## 10. Design Goal

TindaTala should feel like a neat, friendly digital version of a
sari-sari store's inventory notebook: colorful and distinctly Filipino,
but simple enough to use quickly during a busy day.
