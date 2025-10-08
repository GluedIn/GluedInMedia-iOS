//
//  AddToCartViewController.swift
//  GluedIn
//
//  Created by Ashish on 06/09/25.
//

import UIKit
import MobileBuySDK
import GluedInCoreSDK

struct CartLineSelectedOption {
    let name: String
    let value: String
}

struct CartLineVM {
    let lineId: String
    let quantity: Int
    let title: String
    let priceAmount: String
    let currencyCode: String
    let imageURL: URL?
    let selectedOptions: [CartLineSelectedOption]
}

protocol AddToCartDelegate: AnyObject {
    func onTapCheckout(carts: [CartLineVM]?, view: UIViewController?)
}

class AddToCartViewController: UIViewController,
                               UITableViewDelegate,
                               UITableViewDataSource {
    
    @IBOutlet weak var viewSubtotal: UIView!
    @IBOutlet weak var labelSubtotal: UILabel!
    @IBOutlet weak var navView: UIView!
    @IBOutlet weak var buttonBack: UIButton!
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var buttonCheckout: UIButton!
    weak var delegate: AddToCartDelegate?
    var shopifyCartId: String?
    var shopifyCartUrl: String?
    var parentView: UIViewController?
    private var _buyClient: Graph.Client?
    private var cartVM: [CartLineVM] = []
    
    // Empty state image (replace with your own asset if available)
    private let emptyImageView: UIImageView = {
        // If you have a custom asset, replace with: UIImage(named: "icCartEmpty")
        let iv = UIImageView(image: UIImage(named: "icEmptyCart"))
        iv.contentMode = .scaleAspectFit
        iv.tintColor = GluedInAppColor.giTextColorSecondary
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    // Container to vertically stack the image and the label
    private let emptyContainer: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.alignment = .center
        s.spacing = 12
        s.isHidden = true // hidden until first fetch completes
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    // Empty state
    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.text = "Your cart is empty"
        l.textAlignment = .center
        l.numberOfLines = 0
        l.font = .systemFont(ofSize: 16, weight: .medium)
        l.textColor = GluedInAppColor.giTextColorSecondary
        l.isHidden = true // hidden until first fetch completes
        return l
    }()
    
    private var hasLoadedCart = false

    // Total quantity across all cart lines
    private var totalCartQuantity: Int {
        return cartVM.reduce(0) { $0 + $1.quantity }
    }
    
    // Configure SDK client lazily
    private func buyClient() -> Graph.Client? {
        if let existing = _buyClient { return existing }
        let client = Graph.Client(
            shopDomain: ShopifyConfig.shopDomain,
            apiKey: ShopifyConfig.accessToken
        )
        _buyClient = client
        return client
    }
    
    var networkStatus = Reach().connectionStatus()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let nib = UINib(nibName: "AddToCartTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "AddToCartTableViewCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        
        labelSubtotal.text = "0"
        let qty = totalCartQuantity
        labelTitle.text = "Your Cart (\(qty == 0 ? "0" : String(format: "%02d", qty)))"
        
        buttonCheckout.setTitle("Checkout", for: .normal)
        buttonCheckout.setTitleColor(GluedInAppColor.giWhiteWithAlpha(alpha: 1.0), for: .normal)
        buttonCheckout.titleLabel?.font = .textStyleSemibold16
        buttonCheckout.backgroundColor = GluedInAppColor.giButtonActiveColor
        buttonCheckout.layer.cornerRadius = 4.0
        buttonCheckout.layer.masksToBounds = true
        
        // --- Empty state wiring ---
        view.addSubview(emptyContainer)
        emptyContainer.addArrangedSubview(emptyImageView)
        emptyContainer.addArrangedSubview(emptyLabel)

        NSLayoutConstraint.activate([
            emptyContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyContainer.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 16),
            emptyContainer.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16),

            emptyImageView.widthAnchor.constraint(equalToConstant: 100),
            emptyImageView.heightAnchor.constraint(equalToConstant: 100)
        ])

        // Initially: no empty message; subtotal hidden until data arrives
        emptyContainer.isHidden = true
        emptyLabel.isHidden = true
        tableView.isHidden = false
        viewSubtotal.isHidden = true
        buttonCheckout.isEnabled = false
        buttonCheckout.alpha = 0.5
        // --- End empty state wiring ---
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.networkStatusChanged(_:)),
            name: NSNotification.Name(rawValue: ReachabilityStatusChangedNotification),
            object: nil)
        Reach().monitorReachabilityChanges()
    }
    
    @objc func networkStatusChanged(_ notification: Notification) {
        networkStatus = Reach().connectionStatus()
    }
    
    private func updateEmptyState() {
        // Only show empty message after at least one fetch attempt
        guard hasLoadedCart else {
            emptyContainer.isHidden = true
            emptyLabel.isHidden = true
            tableView.isHidden = false
            viewSubtotal.isHidden = true
            buttonCheckout.isEnabled = false
            buttonCheckout.alpha = 0.5
            return
        }
        let isEmpty = cartVM.isEmpty
        emptyContainer.isHidden = !isEmpty
        emptyLabel.isHidden = !isEmpty
        tableView.isHidden = isEmpty
        viewSubtotal.isHidden = isEmpty

        buttonCheckout.isEnabled = !isEmpty
        buttonCheckout.alpha = isEmpty ? 0.5 : 1.0

        if isEmpty {
            labelSubtotal.text = ""
            labelTitle.text = "Your Cart (0)"
        } else {
            let qty = totalCartQuantity
            labelTitle.text = "Your Cart (\(qty == 0 ? "0" : String(format: "%02d", qty)))"
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if (shopifyCartId?.isEmpty == false) { fetchCartProducts { _ in } }
        if shopifyCartId?.isEmpty != false { hasLoadedCart = true; updateEmptyState() }
    }
    
    @IBAction func onClickBack(_ sender: UIButton) {
        navigationController?.popViewController(animated: false)
    }
    
    // MARK: - Public: Fetch / Update / Remove using Storefront Cart API
    func fetchCartProducts(completion: @escaping (Result<[CartLineVM], Error>) -> Void) {
        guard let cartId = shopifyCartId, !cartId.isEmpty else {
            completion(.failure(NSError(domain: "Cart", code: 400, userInfo: [NSLocalizedDescriptionKey: "Missing cart id"]))); return
        }
        guard let client = buyClient() else {
            completion(.failure(NSError(domain: "Cart", code: 500, userInfo: [NSLocalizedDescriptionKey: "Missing Shopify client configuration"]))); return
        }
        let q = Storefront.buildQuery { $0
            .cart(id: GraphQL.ID(rawValue: cartId)) { $0
                .id()
                .checkoutUrl()
                .cost { $0
                    .subtotalAmount { $0.amount().currencyCode() }
                }
                .lines(first: 100) { $0
                    .edges { $0
                        .node { $0
                            .id()
                            .quantity()
                            .merchandise { $0
                                .onProductVariant { $0
                                    .id()
                                    .title()
                                    .selectedOptions { $0
                                        .name()
                                        .value()
                                    }
                                    .price { $0.amount().currencyCode() }
                                    .product { $0
                                        .title()
                                        .images(first: 1) { $0
                                            .edges { $0
                                                .node { $0.url() }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        let task  = client.queryGraphWith(q) { response, error in
            if let error = error { completion(.failure(error)); return }
            // Treat a nil cart as an empty cart instead of an error
            if response?.cart == nil {
                self.cartVM = []
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.hasLoadedCart = true
                    self.labelSubtotal.text = ""
                    self.labelTitle.text = "Your Cart (0)"
                    self.tableView.reloadData()
                    self.updateEmptyState()
                }
                completion(.success([]))
                return
            }
            guard let cart = response?.cart else { return }
            // Map to VMs
            let lines = cart.lines.edges.compactMap { edge -> CartLineVM? in
                let node = edge.node
                guard let merch = node.merchandise as? Storefront.ProductVariant else { return nil }
                let priceAmt = merch.price.amount.description
                let curr = merch.price.currencyCode.rawValue
                let imgURL = (merch.product.images.edges.first?.node.url).flatMap { URL(string: $0.absoluteString) }
                let opts: [CartLineSelectedOption] = merch.selectedOptions.map { CartLineSelectedOption(name: $0.name, value: $0.value) }
                return CartLineVM(
                    lineId: node.id.rawValue,
                    quantity: Int(node.quantity),
                    title: merch.product.title,
                    priceAmount: priceAmt,
                    currencyCode: curr,
                    imageURL: imgURL,
                    selectedOptions: opts
                )
            }
            self.cartVM = lines
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.hasLoadedCart = true
                // Update subtotal label
                let sub = cart.cost.subtotalAmount
                self.labelSubtotal.text = Global.shared.formatPrice(from: "\(sub.currencyCode) \(sub.amount)")
                let qty = self.totalCartQuantity
                self.labelTitle.text = "Your Cart (\(qty == 0 ? "0" : String(format: "%02d", qty)))"
                self.tableView.reloadData()
                self.updateEmptyState()
            }
            completion(.success(lines))
        }
        task.resume()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cartVM.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "AddToCartTableViewCell",
            for: indexPath
        ) as? AddToCartTableViewCell else {
            return UITableViewCell()
        }
        let item = cartVM[indexPath.row]
        cell.post = item
        cell.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Tapped on product \(indexPath.row + 1)")
    }
    
    @IBAction func onclickCheckout(_ sender: UIButton) {
        delegate?.onTapCheckout(carts: cartVM, view: parentView)
    }
    
    // MARK: - Cart line mutations (update / remove)
    private func mapCartToVM(_ cart: Storefront.Cart) -> [CartLineVM] {
        return cart.lines.edges.compactMap { edge -> CartLineVM? in
            let node = edge.node
            guard let merch = node.merchandise as? Storefront.ProductVariant else { return nil }
            let imgURL = (merch.product.images.edges.first?.node.url).flatMap { URL(string: $0.absoluteString) }
            let opts: [CartLineSelectedOption] = merch.selectedOptions.map { CartLineSelectedOption(name: $0.name, value: $0.value) }
            return CartLineVM(
                lineId: node.id.rawValue,
                quantity: Int(node.quantity),
                title: merch.product.title,
                priceAmount: merch.price.amount.description,
                currencyCode: merch.price.currencyCode.rawValue,
                imageURL: imgURL,
                selectedOptions: opts
            )
        }
    }

    private func refreshUI(from cart: Storefront.Cart) {
        hasLoadedCart = true
        let sub = cart.cost.subtotalAmount
        self.labelSubtotal.text = Global.shared.formatPrice(from: "\(sub.currencyCode) \(sub.amount)")
        let qty = totalCartQuantity
        labelTitle.text = "Your Cart (\(qty == 0 ? "0" : String(format: "%02d", qty)))"
        self.tableView.reloadData()
        self.updateEmptyState()
    }

    private func updateCartLine(lineId: String, quantity: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let cartId = shopifyCartId, !cartId.isEmpty else {
            completion(.failure(NSError(domain: "Cart", code: 400, userInfo: [NSLocalizedDescriptionKey: "Missing cart id"]))); return
        }
        guard let client = buyClient() else {
            completion(.failure(NSError(domain: "Cart", code: 500, userInfo: [NSLocalizedDescriptionKey: "Missing Shopify client configuration"]))); return
        }
        let m = Storefront.buildMutation { $0
            .cartLinesUpdate(cartId: GraphQL.ID(rawValue: cartId), lines: [
                Storefront.CartLineUpdateInput.create(
                    id: GraphQL.ID(rawValue: lineId),
                    quantity: Input.value(Int32(quantity))
                )
            ]) { $0
                .cart { $0
                    .id()
                    .cost { $0.subtotalAmount { $0.amount().currencyCode() } }
                    .lines(first: 100) { $0
                        .edges { $0
                            .node { $0
                                .id()
                                .quantity()
                                .merchandise { $0
                                    .onProductVariant { $0
                                        .id()
                                        .title()
                                        .selectedOptions { $0     // ← REQUIRED
                                            .name()
                                            .value()
                                        }
                                        .price { $0.amount().currencyCode() }
                                        .product { $0
                                            .title()
                                            .images(first: 1) { $0
                                                .edges { $0
                                                    .node { $0.url() }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .userErrors { $0.field().message() }
            }
        }
        let task = client.mutateGraphWith(m) { [weak self] response, error in
            guard let self = self else { return }
            if let error = error { completion(.failure(error)); return }
            if let msg = response?.cartLinesUpdate?.userErrors.first?.message {
                completion(.failure(NSError(domain: "Cart", code: 422, userInfo: [NSLocalizedDescriptionKey: msg]))); return
            }
            if let cart = response?.cartLinesUpdate?.cart {
                self.cartVM = self.mapCartToVM(cart)
                DispatchQueue.main.async { self.refreshUI(from: cart) }
            }
            completion(.success(()))
        }
        task.resume()
    }

    private func removeCartLine(lineId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let cartId = shopifyCartId, !cartId.isEmpty else {
            completion(.failure(NSError(domain: "Cart", code: 400, userInfo: [NSLocalizedDescriptionKey: "Missing cart id"]))); return
        }
        guard let client = buyClient() else {
            completion(.failure(NSError(domain: "Cart", code: 500, userInfo: [NSLocalizedDescriptionKey: "Missing Shopify client configuration"]))); return
        }
        let m = Storefront.buildMutation { $0
            .cartLinesRemove(cartId: GraphQL.ID(rawValue: cartId),
                             lineIds: [ GraphQL.ID(rawValue: lineId) ]) { $0
                .cart { $0
                    .id()
                    .cost { $0.subtotalAmount { $0.amount().currencyCode() } }
                    .lines(first: 100) { $0
                        .edges { $0
                            .node { $0
                                .id()
                                .quantity()
                                .merchandise { $0
                                    .onProductVariant { $0
                                        .id()
                                        .title()
                                        .selectedOptions { $0     // ← REQUIRED
                                            .name()
                                            .value()
                                        }
                                        .price { $0.amount().currencyCode() }
                                        .product { $0
                                            .title()
                                            .images(first: 1) { $0
                                                .edges { $0
                                                    .node { $0.url() }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .userErrors { $0.field().message() }
            }
        }
        let task = client.mutateGraphWith(m) { [weak self] response, error in
            guard let self = self else { return }
            if let error = error { completion(.failure(error)); return }
            if let msg = response?.cartLinesRemove?.userErrors.first?.message {
                completion(.failure(NSError(domain: "Cart", code: 422, userInfo: [NSLocalizedDescriptionKey: msg]))); return
            }
            if let cart = response?.cartLinesRemove?.cart {
                self.cartVM = self.mapCartToVM(cart)
                DispatchQueue.main.async { self.refreshUI(from: cart) }
            }
            completion(.success(()))
        }
        task.resume()
    }
}

extension AddToCartViewController: AddToCartTableViewCellDelegate {
    
    func onTapDelete(post: CartLineVM?) {
        switch networkStatus {
        case .offline:
            ToastManager.shared.showToast(text: "Unable to update the cart.")
        case .online:
            guard let lineId = post?.lineId else { return }
            removeCartLine(lineId: lineId) { result in
                if case let .failure(err) = result {
                    ToastManager.shared.showToast(text: "Unable to update the cart.")
                }
            }
            
        default:
            break
        }        
    }
    
    func onTapUpdate(post: CartLineVM?, quantity: Int) {
        switch networkStatus {
        case .offline:
            ToastManager.shared.showToast(text: "Unable to update the cart.")
        case .online:
            guard let lineId = post?.lineId else { return }
            // Enforce minimum 1 at the controller level as well
            let safeQty = max(1, quantity)
            updateCartLine(lineId: lineId, quantity: safeQty) { result in
                if case let .failure(err) = result {
                    ToastManager.shared.showToast(text: "Unable to update the cart.")
                }
            }
            
        default:
            break
        }
        
    }

}
