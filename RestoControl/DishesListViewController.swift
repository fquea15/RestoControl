import UIKit
import FirebaseDatabase
import SDWebImage

class DishesListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    
    @IBOutlet weak var imageTest: UIImageView!
    @IBOutlet weak var listDishesTable: UITableView!
    var dishes:[Dish] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        listDishesTable.delegate = self
        listDishesTable.dataSource = self
        getDishes()
    }
    
    //LIST DISHES
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dishes.count
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
        
        dishesRef.removeValue { (error, _) in
            if let error = error {
                print("Error deleting dish from database: \(error.localizedDescription)")
            } else {
                print("Dish deleted successfully")
                
                // Verificar que el indexPath sea válido antes de intentar eliminar la fila de la tabla
                guard indexPath.row < self.dishes.count else {
                    print("Invalid indexPath")
                    return
                }

                // Verificar que el indexPath esté dentro del rango de filas de la tabla
                if self.listDishesTable.numberOfRows(inSection: indexPath.section) > indexPath.row {
                    self.dishes.remove(at: indexPath.row)
                    self.listDishesTable.deleteRows(at: [indexPath], with: .fade)
                }
            }
        }
    }


    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "list")
        let dish = dishes[indexPath.row]
        cell.textLabel?.text = dish.name
        cell.detailTextLabel?.text = dish.description
        //cell.imageView?.image = UIImage(named: "logo-rest.png")
        
        cell.imageView?.sd_setImage(with: URL(string: dish.imagenURL), placeholderImage: UIImage(named: "logo-rest.png"), options: [], completed: { (image, error, cacheType, imageURL) in
            guard let resizedImage = self.resizedImage(image: image,newWidht:60) else {
                cell.imageView?.image = UIImage(named: "logo-rest.png")
                return
            }
            cell.imageView?.image = resizedImage
        })
        
//        cell.imageView?.image = UIImage(
//            .sd_setImage(with: URL(string: dish.imagenURL), completed: nil)
        /*if let imageUrl = URL(string: dish.imagenURL) {
            cell.imageView!.sd_setImage(with: imageUrl, completed: { (image, error, cacheType, imageURL) in
                if let error = error {
                    print("Error loading image: \(error.localizedDescription)")
                }
            })
        } else {
            cell.imageView?.image = UIImage(named: "logo-rest.png")
        }*/

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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedDish = dishes[indexPath.row]
        performSegue(withIdentifier: "ShowDetalleDishSegue", sender: selectedDish)
    }
    
    
    //ADD DISH
    @IBAction func addDishTapped(_ sender: Any) {
        //imageTest.sd_setImage(with: URL(string: dishes[0].imagenURL), completed: nil)
        performSegue(withIdentifier: "addNewDish", sender: nil)
        
    }
    
    //ACTIONS SESION
    @IBAction func logoutTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    func getDishes () {
        let ref = Database.database().reference()
        
        let dishesRef = ref.child("dishes")
        
        dishesRef.observe(DataEventType.childAdded, with: {
            (snapshot) in
            let dish = Dish()
            dish.id = snapshot.key
            dish.name = (snapshot.value as! NSDictionary)["name"] as! String
            dish.category = (snapshot.value as! NSDictionary)["category"] as! String
            dish.type = (snapshot.value as! NSDictionary)["type"] as! String
            dish.price = (snapshot.value as! NSDictionary)["price"] as! String
            dish.description = (snapshot.value as! NSDictionary)["description"] as! String
            if let imageDict = snapshot.childSnapshot(forPath: "image").value as? NSDictionary {
                dish.imagenID = imageDict["id"] as? String ?? ""
                dish.imagenURL = imageDict["url"] as? String ?? ""
            }

            print(dish.imagenURL)
            self.dishes.append(dish)
            self.listDishesTable.reloadData()

        })
        dishesRef.observe(DataEventType.childRemoved, with: { (snapshot) in
                let removedDishId = snapshot.key
                // Filtrar y mantener los elementos que no coinciden con el ID eliminado
                self.dishes = self.dishes.filter { $0.id != removedDishId }
                self.listDishesTable.reloadData()
            })
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
}

extension DishesListViewController: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return HalfModalPresentationController(presentedViewController: presented, presenting: presenting)
    }
}
