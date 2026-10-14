# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

Four roles share one system, each with a different job and a different
tolerance for density:

- **Buyer (普通用户)** — a photography enthusiast or working shooter comparing
  gear by specification and price. Browses on a laptop in the evening and on a
  phone in the field. Job: find the right body/lens/accessory at a credible
  price, and trust that what arrives matches the listing.
- **Merchant (商家)** — a camera shop or a rental house. Runs the store from a
  desktop during business hours. Job: publish accurate listings, keep stock
  honest, and move orders through packing and shipping without mistakes.
- **Platform admin (管理员)** — reviews merchant credentials and product
  listings, manages categories, brands, notices, and users. Job: clear a review
  queue quickly and consistently, and be able to justify a rejection.
- **Super admin (超级管理员)** — owns roles and permissions. Job: grant the
  minimum access and be able to see who holds what.

## Product Purpose

A single system to trade photographic equipment in three modes — new retail
(全新), second-hand (二手), and rental (租赁) — with platform-level review of
merchants and listings, order fulfilment across all three modes, and stock that
stays truthful through the order lifecycle.

Success means a merchant can list a product and a buyer can receive it without
either side hitting an unexplained error, and a platform admin can audit a
listing with the evidence in front of them.

## Positioning

Three commerce modes on one stock and order spine. A camera body in this system
carries one inventory record and one order lifecycle whether it is sold new,
resold used, or rented out. Most implementations fork the three modes into three
separate flows; here the mode is an attribute, not a parallel system.

## Operating Context

- Rental orders carry a deposit, a rental window, and an overdue clock; an
  overdue rental escalates to an account freeze.
- Second-hand listings are single-unit and condition-graded, not stock-backed.
- New-retail listings are audited by the platform before they become visible.
- Product data is specification-heavy: mount, sensor, focal range, aperture,
  condition grade, shutter count.
- Photography is a visual purchase; listings live or die on image quality.

## Capabilities and Constraints

Stack is fixed and must not change: Spring Boot 3.5 + MyBatis-Plus + MySQL +
Redis on the server; Vue 3 + Element Plus + Pinia + vue-router + Vite on the
client. Both already exist and are being refactored, not rebuilt.

Capabilities already present in the codebase: auth with captcha and email reset,
cart, favourites, addresses, orders across three modes, payment records,
refunds, evaluations with replies, merchant shop profile and credentials review,
platform user/merchant/product audit, category and brand trees, notices and
in-app messages, inventory with adjustment history, and a role/permission
matrix.

Confirmed terminology (keep these words): 加购物车, 立即购买, 库存, 安全库存,
审核, 上架, 下架, 发货, 确认收货, 售后, 押金, 租期, 成色.

## Brand Commitments

Product name: 摄影器材交易系统. The camera-graphic mark at `相机.png` is the
existing logo and stays.

## Evidence on Hand

- Live MySQL schema and seed data in `数据库文件/`.
- Product imagery for Nikon, Canon, Sony, Fujifilm, Dji, GoPro, Insta360,
  Panasonic, Leica, Sigma, Tamron, AKASO, Skydio, Parrot, Autel under
  `BYSJ.PETS.FEC/public/`.

Absent, and must not be invented: customer counts, GMV, review scores, press
coverage, partnership logos, or delivery-time promises.

## Product Principles

1. **The photograph is the product.** Interface chrome recedes; listing imagery
   gets the space and the resolution.
2. **Specifications decide the sale.** Mount, sensor, aperture, and condition are
   read as data, so they are set as data — aligned, comparable, never prose.
3. **Money and stock are never ambiguous.** Price, deposit, rent, and remaining
   stock are stated plainly and never softened.
4. **Review is a decision with evidence.** An auditor sees the listing, the
   merchant's credentials, and the rejection reason field together.
5. **One system, four densities.** Buyers get air, merchants get throughput,
   admins get queues. The visual language is shared; the density is not.

## Accessibility & Inclusion

Body text and placeholder text meet 4.5:1 against their surface. Every control is
reachable and operable by keyboard, with a visible focus ring. Status is never
carried by colour alone: order, audit, and stock states always pair colour with a
written label.
