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
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "list")
        let dish = dishes[indexPath.row]
        cell.textLabel?.text = dish.name
        cell.detailTextLabel?.text = dish.description
        cell.imageView?.contentMode = .scaleAspectFit
        cell.imageView?.image = UIImage(named: "logo-rest.png")
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

            self.dishes.append(dish)
            
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
