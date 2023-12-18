import UIKit
import FirebaseDatabase
import SDWebImage
import FirebaseStorage

class DishesListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    
    @IBOutlet weak var imageTest: UIImageView!
    @IBOutlet weak var listDishesTable: UITableView!
    
    var dishes:[Dish] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        listDishesTable.delegate = self
        listDishesTable.dataSource = self
        
    }
    override func viewWillAppear(_ animated: Bool) {
        getDishes()
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dishes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "list")
        let dish = dishes[indexPath.row]
        cell.textLabel?.text = dish.name
        cell.detailTextLabel?.text = dish.description
        
        cell.imageView?.sd_setImage(with: URL(string: dish.imagenURL),
                                    placeholderImage: UIImage(named: "logo-rest.png"),
                                    options: [], completed: {
            (image, error, cacheType, imageURL) in
            guard let resizedImage = self.resizedImage(image: image,newWidht:60) else {
                cell.imageView?.image = UIImage(named: "logo-rest.png")
                return
            }
            cell.imageView?.image = resizedImage
        })
        return cell
    }
    func resizedImage(image:UIImage?, newWidht: CGFloat) -> UIImage? {
        guard let image = image else {
            return nil
        }
        UIGraphicsBeginImageContext(CGSize(width: newWidht, height: newWidht))
        image.draw(in: CGRect(x: 0 , y:0,width: newWidht,height: newWidht))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        return newImage
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let deletedDish = dishes[indexPath.row]
            deleteDishFromDatabase(dish: deletedDish, at: indexPath)
        }
    }
    func deleteDishFromDatabase(dish: Dish, at indexPath: IndexPath) {
        let ref = Database.database().reference()
        let dishesRef = ref.child("dishes").child(dish.id)
        Storage.storage().reference().child("images").child(dish.imagenID).delete { (error) in
            if let error = error {
                print("Error deleting image: \(error.localizedDescription)")
            } else {
                print("Image deleted successfully")
                
                dishesRef.removeValue { (dbError, _) in
                    if let dbError = dbError {
                        print("Error deleting dish from database: \(dbError.localizedDescription)")
                    } else {
                        print("Dish deleted successfully")
                        self.dishes.remove(at: indexPath.row)
                        self.listDishesTable.deleteRows(at: [indexPath], with: .fade)
                    }
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedDish = dishes[indexPath.row]
        performSegue(withIdentifier: "ShowDetalleDishSegue", sender: selectedDish)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowDetalleDishSegue" {
            if let detalleDishVC = segue.destination as? DetalleDishViewController,
               let selectedDish = sender as? Dish {
                detalleDishVC.selectedDish = selectedDish
                detalleDishVC.modalPresentationStyle = .custom
                detalleDishVC.transitioningDelegate = self
            }
        }
    }
    
    @IBAction func addDishTapped(_ sender: Any) {
        performSegue(withIdentifier: "addNewDish", sender: nil)
        
    }
    @IBAction func logoutTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }                    
    
    func getDishes() {
        let ref = Database.database().reference()
        let dishesRef = ref.child("dishes")

        // Evento para agregar nuevos platos
        dishesRef.observe(DataEventType.childAdded, with: { (snapshot) in
            self.handleDishAdded(snapshot: snapshot)
        })

        // Evento para cambios en los platos existentes
        dishesRef.observe(DataEventType.childChanged, with: { (snapshot) in
            self.handleDishChanged(snapshot: snapshot)
        })

        // Evento para eliminar platos
        /*dishesRef.observe(DataEventType.childRemoved, with: { (snapshot) in
            self.handleDishRemoved(snapshot: snapshot)
        })*/
    }

    // Función para manejar la adición de nuevos platos
    func handleDishAdded(snapshot: DataSnapshot) {
        let newDish = Dish()
        newDish.id = snapshot.key
        newDish.name = (snapshot.value as! NSDictionary)["name"] as! String
        newDish.category = (snapshot.value as! NSDictionary)["category"] as! String
        newDish.type = (snapshot.value as! NSDictionary)["type"] as! String
        newDish.price = (snapshot.value as! NSDictionary)["price"] as! String
        newDish.description = (snapshot.value as! NSDictionary)["description"] as! String
        if let imageDict = snapshot.childSnapshot(forPath: "image").value as? NSDictionary {
            newDish.imagenID = imageDict["id"] as? String ?? ""
            newDish.imagenURL = imageDict["url"] as? String ?? ""
        }

        if !self.arrayContaisID(snapshot.key) {
            self.dishes.append(newDish)
            self.listDishesTable.reloadData()
        }
    }

    // Función para manejar cambios en platos existentes
    func handleDishChanged(snapshot: DataSnapshot) {
        let updatedDish = Dish()
        updatedDish.id = snapshot.key
        updatedDish.name = (snapshot.value as! NSDictionary)["name"] as! String
        updatedDish.category = (snapshot.value as! NSDictionary)["category"] as! String
        updatedDish.type = (snapshot.value as! NSDictionary)["type"] as! String
        updatedDish.price = (snapshot.value as! NSDictionary)["price"] as! String
        updatedDish.description = (snapshot.value as! NSDictionary)["description"] as! String
        if let imageDict = snapshot.childSnapshot(forPath: "image").value as? NSDictionary {
            updatedDish.imagenID = imageDict["id"] as? String ?? ""
            updatedDish.imagenURL = imageDict["url"] as? String ?? ""
        }

        if let index = self.dishes.firstIndex(where: { $0.id == updatedDish.id }) {
            self.dishes[index] = updatedDish
            self.listDishesTable.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
        }
    }

    // Función para manejar la eliminación de platos
    func handleDishRemoved(snapshot: DataSnapshot) {
        if let index = self.dishes.firstIndex(where: { $0.id == snapshot.key }) {
            self.dishes.remove(at: index)
            self.listDishesTable.deleteRows(at: [IndexPath(row: index, section: 0)], with: .fade)
        }
    }

    func arrayContaisID(_ id: String) -> Bool {
        return dishes.contains{
            element in
            return element.id == id
        }
    }
}

extension DishesListViewController: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return HalfModalPresentationController(presentedViewController: presented, presenting: presenting)
    }
}
