import UIKit
import FirebaseDatabase
import FirebaseStorage

class AddDishViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var categoryPicker: UIPickerView!
    @IBOutlet weak var typePicker: UIPickerView!
    @IBOutlet weak var priceTextField: UITextField!
    @IBOutlet weak var descriptionTextField: UITextField!
    @IBOutlet weak var imageView: UIImageView!

    var imagePicker: UIImagePickerController!
    var categories: [String] = ["Categoría 1", "Categoría 2", "Categoría 3"]
    var types: [String] = ["Tipo 1", "Tipo 2", "Tipo 3"]
    override func viewDidLoad() {
        super.viewDidLoad()

        imagePicker = UIImagePickerController()
        imagePicker.delegate = self

        categoryPicker.delegate = self
        categoryPicker.dataSource = self

        typePicker.delegate = self
        typePicker.dataSource = self
    }

    @IBAction func addDishTapped(_ sender: Any) {
        guard let name = nameTextField.text, !name.isEmpty,
              let price = priceTextField.text, !price.isEmpty,
              let description = descriptionTextField.text, !description.isEmpty,
              let dishImage = imageView.image else {
            return
        }

        let selectedCategory = categories[categoryPicker.selectedRow(inComponent: 0)]
        let selectedType = types[typePicker.selectedRow(inComponent: 0)]

        uploadImage(dishImage) { imageUrl in
            let dishData: [String: Any] = [
                "name": name,
                "category": selectedCategory,
                "type": selectedType,
                "price": price,
                "description": description,
                "image": [
                    "id": UUID().uuidString,
                    "url": imageUrl
                ]
            ]

            self.addDishToDatabase(dishData)
        }
    }

    func uploadImage(_ image: UIImage, completion: @escaping (String) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            return
        }

        let imageId = UUID().uuidString
        let storageRef = Storage.storage().reference().child("images/\(imageId).jpg")

        storageRef.putData(imageData, metadata: nil) { (_, error) in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
            } else {
                storageRef.downloadURL { (url, error) in
                    if let imageUrl = url?.absoluteString {
                        completion(imageUrl)
                    }
                }
            }
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
                //self.dismiss(animated: true, completion: nil)
                self.navigationController?.popViewController(animated: true)
            }
        }
    }

    @IBAction func selectImageTapped(_ sender: Any) {
        present(imagePicker, animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
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
}
