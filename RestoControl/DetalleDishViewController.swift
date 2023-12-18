//
//  DetalleDishViewController.swift
//  RestoControl
//
//  Created by Ruben Freddy Quea Jacho on 12/12/23.
//

import UIKit
import SDWebImage
import FirebaseDatabase

class DetalleDishViewController: UIViewController {

    var selectedDish: Dish?
    var dishId: String?
    
    let databaseRef = Database.database().reference()
    var ratings:[Rating] = []

    //BAR-NAVIGATOR
    @IBOutlet weak var detallBar: UINavigationItem!
    
    //LABEL
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!

    @IBOutlet weak var modalView: UIView!
    //@IBOutlet weak var handleArea: UIView!

    var presenter: UIViewPropertyAnimator?
    
    //CALCULAR RATING
    var ratingDish: Float = 0.0

    override func viewDidLoad() {
        super.viewDidLoad()

        setupModalView()
        //setupGesture()

        if let dish = selectedDish {
            detallBar.title = dish.name
            categoryLabel.text = dish.category
            typeLabel.text = dish.type
            priceLabel.text = "S/.\(dish.price)"
            descriptionLabel.text = dish.description
            if let imageUrl = URL(string: dish.imagenURL) {
                imageView.sd_setImage(with: imageUrl, completed: nil)
            }
            dishId = dish.id
        }
        //observeDishChanges()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        observeDishChanges()
    }

    private func setupModalView() {
        modalView.layer.cornerRadius = 12
        modalView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }

    /*private func setupGesture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        handleArea.addGestureRecognizer(panGesture)
    }*/

    @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: modalView)

        switch recognizer.state {
        case .began:
            presenter = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 0.8) {
                self.modalView.transform = CGAffineTransform(translationX: 0, y: 0)
            }
            presenter?.startAnimation()
            presenter?.pauseAnimation()
        case .changed:
            presenter?.fractionComplete = translation.y / 200
        case .ended:
            let velocity = recognizer.velocity(in: modalView).y

            if velocity > 0 {
                presenter?.addAnimations {
                    self.modalView.transform = CGAffineTransform(translationX: 0, y: self.view.bounds.height)
                }
                presenter?.addCompletion { _ in
                    self.dismiss(animated: false, completion: nil)
                }
            } else {
                presenter?.isReversed = true
            }

            presenter?.continueAnimation(withTimingParameters: nil, durationFactor: 0)
        default:
            break
        }
    }

    func getRating(id_dish: String, completion: @escaping () -> ()) {
        print("Hola Estoy Aqui")
        let ratingsRef = databaseRef.child("dishes").child(id_dish).child("ratings")
        
        ratingsRef.observe(DataEventType.childAdded, with: { (snapshot) in
            if let ratingData = snapshot.value as? [String: Any],
               let ratingNumber = ratingData["rating"] as? NSNumber {
                
                let rating = Rating()
                rating.rating = ratingNumber.floatValue
                self.ratings.append(rating)
            }
        })
    }

    /*@IBAction func cerrarVentanaTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }*/
    
    @IBAction func editTapped(_ sender: Any) {
        performSegue(withIdentifier: "editDish", sender: self.selectedDish)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editDish" {
            if let editDishVC = segue.destination as? AddDishViewController,
               let selectedDish = sender as? Dish {
                editDishVC.dish = selectedDish
                // Asigna la clausura para manejar las actualizaciones en DetalleDishViewController
                editDishVC.didEditDish = { editedDish in
                    // Implementa aquí la lógica para actualizar la interfaz en DetalleDishViewController
                    // Puedes acceder a "editedDish" que contiene el platillo editado
                    self.updateUI(with: editedDish)
                }
            }
        }
    }
    
    func observeDishChanges() {
        guard let dishId = dishId else {
            return
        }

        let dishRef = databaseRef.child("dishes").child(dishId)

        // Observar cambios en el plato específico
        dishRef.observe(DataEventType.value, with: { (snapshot) in
            self.handleDishChanges(snapshot: snapshot)
        })
    }
    
    func handleDishChanges(snapshot: DataSnapshot) {
        if let dishData = snapshot.value as? [String: Any] {
            let updatedDish = Dish()
            updatedDish.id = snapshot.key
            updatedDish.name = dishData["name"] as? String ?? ""
            updatedDish.category = dishData["category"] as? String ?? ""
            updatedDish.type = dishData["type"] as? String ?? ""
            updatedDish.price = dishData["price"] as? String ?? ""
            updatedDish.description = dishData["description"] as? String ?? ""

            if let imageDict = dishData["image"] as? [String: String] {
                updatedDish.imagenID = imageDict["id"] ?? ""
                updatedDish.imagenURL = imageDict["url"] ?? ""
            }
            updateUI(with: updatedDish)
        }
    }

    func updateUI(with dish: Dish) {
        detallBar.title = dish.name
        categoryLabel.text = dish.category
        typeLabel.text = dish.type
        priceLabel.text = "S/.\(dish.price)"
        descriptionLabel.text = dish.description
        if let imageUrl = URL(string: dish.imagenURL) {
            imageView.sd_setImage(with: imageUrl, completed: nil)
        }
    }
    
}
