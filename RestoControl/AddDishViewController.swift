import UIKit
import FirebaseDatabase
import FirebaseStorage

class AddDishViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    var didEditDish: ((Dish) -> Void)?

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var categoryPicker: UIPickerView!
    @IBOutlet weak var typePicker: UIPickerView!
    @IBOutlet weak var priceTextField: UITextField!
    @IBOutlet weak var descriptionTextField: UITextField!
    @IBOutlet weak var imageView: UIImageView!
    
    //BOTONES
    
    @IBOutlet weak var buttonAdd: UIButton!
    @IBOutlet weak var buttonUpdate: UIButton!
    @IBOutlet weak var ButtonChangeImage: UIButton!
    
    //NAVBAR
    @IBOutlet weak var navbarAddDish: UINavigationItem!
    @IBOutlet weak var titleAddUpdateDish: UILabel!
    
    
    var imagePicker: UIImagePickerController!
    var categories: [String] = ["Carnes", "Mariscos", "Pollo", "Aperitivo", "Leche", "Queso", "Cremosa", "Pasta", "Dulces"]
    var types: [String] = ["Entrada", "Principal", "Postre"]
    var dish: Dish?
    
    var imageId = ""
    var overlayView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        imagePicker = UIImagePickerController()
        imagePicker.delegate = self

        categoryPicker.delegate = self
        categoryPicker.dataSource = self

        typePicker.delegate = self
        typePicker.dataSource = self
        
        
        if let dish = dish {
            nameTextField.text = dish.name
            if let categoryIndex = categories.firstIndex(of: dish.category),
               let typeIndex = types.firstIndex(of: dish.type) {
                categoryPicker.selectRow(categoryIndex, inComponent: 0, animated: false)
                typePicker.selectRow(typeIndex, inComponent: 0, animated: false)
            }

            priceTextField.text = (dish.price)
            descriptionTextField.text = dish.description
            if let imageUrl = URL(string: dish.imagenURL) {
                imageView.sd_setImage(with: imageUrl, completed: nil)
            }
            
            buttonAdd.setTitle("Cancelar", for: .normal)
            buttonAdd.backgroundColor = UIColor.red
            buttonUpdate.isHidden = false
            ButtonChangeImage.isHidden = false
            titleAddUpdateDish.text = "ACTUALIZAR PLATILLO"
        }else {
            buttonAdd.setTitle("Agregar", for: .normal)
            buttonAdd.backgroundColor = UIColor.blue
            navbarAddDish.title = "AGREGAR"
            titleAddUpdateDish.text = "NUEVO PLATILLO"
            
            overlayView = UIView(frame: imageView.bounds)
            overlayView.backgroundColor = UIColor.gray
            imageView.addSubview(overlayView)

            let placeholderLabel = UILabel()
            placeholderLabel.text = "Insertar Imagen"
            placeholderLabel.textColor = .black
            placeholderLabel.textAlignment = .center
            placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
            overlayView.addSubview(placeholderLabel)

            placeholderLabel.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor).isActive = true
            placeholderLabel.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor).isActive = true
        }
    }

    @IBAction func addDishTapped(_ sender: Any) {
        if let title = buttonAdd.title(for: .normal){
            if title == "Agregar"{
                guard let name = nameTextField.text, !name.isEmpty,
                      let price = priceTextField.text, !price.isEmpty,
                      let description = descriptionTextField.text, !description.isEmpty,
                      let dishImage = imageView.image else {
                    showAlert(title: "Campos Incompletos", message: "Por favor, complete todos los campos.")
                    return
                }

                let selectedCategory = categories[categoryPicker.selectedRow(inComponent: 0)]
                let selectedType = types[typePicker.selectedRow(inComponent: 0)]

                uploadImageWithProgress(dishImage) { imageUrl, error in
                    if let error = error {
                        self.showAlert(title: "Error", message: "Error al cargar la imagen: \(error.localizedDescription)")
                    } else if let imageUrl = imageUrl {
                        let dishData: [String: Any] = [
                            "name": name,
                            "category": selectedCategory,
                            "type": selectedType,
                            "price": price,
                            "description": description,
                            "image": [
                                "id": "\(self.imageId).jpg",
                                "url": imageUrl
                            ]
                        ]

                        self.addDishToDatabase(dishData)
                    }
                }
            } else if title == "Cancelar"{
                dismiss(animated: true, completion: nil)
            }
        }
        
    }
    
func uploadImageWithProgress(_ image: UIImage, completion: @escaping (String?, Error?) -> Void) {
    guard let imageData = image.jpegData(compressionQuality: 0.5) else {
        completion(nil, NSError(domain: "YourAppDomain", code: 0, userInfo: [NSLocalizedDescriptionKey: "Error al obtener datos de imagen"]))
        return
    }
    imageId = UUID().uuidString
        let storageRef = Storage.storage().reference().child("images/\(imageId).jpg")

        // Mostrar alerta de progreso
        let progressAlert = UIAlertController(title: "Cargando", message: "Por favor, espera...", preferredStyle: .alert)
        present(progressAlert, animated: true, completion: nil)

        let uploadTask = storageRef.putData(imageData, metadata: nil) { (metadata, error) in
            // Ocultar la alerta de progreso al finalizar la carga
            progressAlert.dismiss(animated: true, completion: nil)

            if let error = error {
                completion(nil, error)
            } else {
                storageRef.downloadURL { (url, error) in
                    if let imageUrl = url?.absoluteString {
                        completion(imageUrl, nil)
                    } else {
                        completion(nil, error)
                    }
                }
            }
        }

        // Observar el progreso de la carga
        uploadTask.observe(.progress) { snapshot in
            guard let progress = snapshot.progress else { return }
            let percentComplete = Float(progress.completedUnitCount) / Float(progress.totalUnitCount)
            progressAlert.message = "Cargando... \(Int(percentComplete * 100))%"
        }
    }

    func addDishToDatabase(_ dishData: [String: Any]) {
        let ref = Database.database().reference()
        let dishesRef = ref.child("dishes")
        let newDishRef = dishesRef.childByAutoId()
        newDishRef.setValue(dishData) { (error, _) in
            if let error = error {
                print("Error adding dish to database: \(error.localizedDescription)")
            } else {
                print("Dish added successfully")
                self.navigationController?.popViewController(animated: true)
            }
        }
    }

    @IBAction func selectImageTapped(_ sender: Any) {
        present(imagePicker, animated: true, completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
            if dish == nil{
                overlayView.removeFromSuperview()
            }

            imageView.image = selectedImage
        }
        dismiss(animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == categoryPicker {
            return categories.count
        } else if pickerView == typePicker {
            return types.count
        }
        return 0
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == categoryPicker {
            return categories[row]
        } else if pickerView == typePicker {
            return types[row]
        }
        return nil
    }
    
    @IBAction func updateDishTapped(_ sender: Any) {
        guard let name = nameTextField.text, !name.isEmpty,
              let price = priceTextField.text, !price.isEmpty,
              let description = descriptionTextField.text, !description.isEmpty,
              let dishImage = imageView.image else {
            return
        }

        let selectedCategory = categories[categoryPicker.selectedRow(inComponent: 0)]
        let selectedType = types[typePicker.selectedRow(inComponent: 0)]
        if imageView.image != nil {
            deleteImageFromStorage(imageId: dish?.imagenID)
            uploadImageWithProgress(dishImage) { imageUrl, error in
                if let error = error {
                    self.showAlert(title: "Error", message: "Error al cargar la imagen: \(error.localizedDescription)")
                } else if let imageUrl = imageUrl {
                    let updatedDishData: [String: Any] = [
                        "name": name,
                        "category": selectedCategory,
                        "type": selectedType,
                        "price": price,
                        "description": description,
                        "image": [
                            "id": "\(self.imageId).jpg",
                            "url": imageUrl
                        ]
                    ]
                    self.updateDishInDatabase(updatedDishData)
                }
            }
        } else {
            let updatedDishData: [String: Any] = [
                "name": name,
                "category": selectedCategory,
                "type": selectedType,
                "price": price,
                "description": description,
                "image": [
                    "id": dish?.imagenID ?? "",
                    "url": dish?.imagenURL ?? ""
                ]
            ]

            self.updateDishInDatabase(updatedDishData)
        }
    }

    func deleteImageFromStorage(imageId: String?) {
        guard let imageId = imageId else {
            return
        }
 
        let storageRef = Storage.storage().reference().child("images/\(imageId)")
        storageRef.delete { error in
            if let error = error {
                print("Error deleting image from storage: \(error.localizedDescription)")
            } else {
                print("Image deleted successfully from storage")
            }
        }
    }

    func updateDishInDatabase(_ dishData: [String: Any]) {
        guard let dish = dish else {
            return
        }

        let ref = Database.database().reference()
        let dishesRef = ref.child("dishes").child(dish.id)
        dishesRef.updateChildValues(dishData) { (error, _) in
            if let error = error {
                print("Error updating dish in database: \(error.localizedDescription)")
            } else {
                print("Dish updated successfully")
                self.didEditDish?(dish)
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func changeImageDishTapped(_ sender: Any) {
        present(imagePicker, animated: true, completion: nil)
    }
    
    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )

        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)

        present(alertController, animated: true, completion: nil)
    }
}
