import SwiftUI
import CloudKit

class CloudKitCrudViewModel: ObservableObject {
    @Published var text: String = ""
    @Published var fruits: [Fruit] = []
    
    init() {
      fetchItems()
    }
    
    func addButtonPressed() {
        if text.isEmpty {
            return
        }
        
        addItem(name: text)
    }
    
    func fetchItems() {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Fruits", predicate: predicate)
        let queryOperation = CKQueryOperation(query: query)
        
        var returnedItems: [Fruit] = []
        
        queryOperation.recordMatchedBlock = { returnedRecordId, returnedResult in
            switch returnedResult {
            case .success(let record):
                guard let name = record["name"] as? String else {
                    return
                }
                returnedItems.append(Fruit(name: name, record: record))
                
            case .failure(let error):
                print("Error recordMatchedBlock: \(error)")
            }
        }
        
        queryOperation.queryResultBlock = { [weak self] returnedResult in
            print("RETURNED RESULT: \(returnedResult)")
            
            DispatchQueue.main.async {
                self?.fruits = returnedItems
            }
        }
        
        addOperation(queryOperation)
    }
    
    func updateItem(fruit: Fruit) {
        let record = fruit.record
        record["name"] = "NEW NAME!!!"
        saveItem(record: record)
    }
    
    func deleteItem(indexSet: IndexSet) {
        guard let index = indexSet.first else {
            return
        }
        
        let fruit = fruits[index]
        let record = fruit.record
        
        CKContainer.default().publicCloudDatabase.delete(
            withRecordID: record.recordID
        ) { [weak self] returnedRecordID, returnedError in
            DispatchQueue.main.async {
                self?.fruits.remove(at: index)
            }
        }
    }
    
    private func addItem(name: String) {
        let newFruitRecord = CKRecord(recordType: "Fruits")
        newFruitRecord["name"] = name
        saveItem(record: newFruitRecord)
    }
    
    private func saveItem(record: CKRecord) {
        CKContainer.default().publicCloudDatabase.save(
            record
        ) { [weak self] returnedRecord, returnedError in
            print("Record: \(returnedRecord)")
            print("Error: \(returnedError)")
            
            DispatchQueue.main.async {
                self?.text = ""
                self?.fetchItems()
            }
        }
    }
    
    private func addOperation(_ operation: CKDatabaseOperation) {
        CKContainer.default().publicCloudDatabase.add(operation)
    }
}

struct CloudKitCrudView: View {
    @StateObject private var vm = CloudKitCrudViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                header
                textField
                addButton
                
                List {
                    ForEach(vm.fruits, id: \.self) { fruit in
                        Text(fruit.name)
                            .onTapGesture {
                                vm.updateItem(fruit: fruit)
                            }
                    }
                    .onDelete(perform: vm.deleteItem)
                }
                .listStyle(PlainListStyle())
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
    
    private var header: some View {
        Text("CloudKit CRUD ☁️☁️☁️")
            .font(.headline)
            .underline()
    }
    
    private var textField: some View {
        TextField("Add something here...", text: $vm.text)
            .frame(height: 55)
            .padding(.leading)
            .background(Color.gray.opacity(0.4))
            .cornerRadius(10)
    }
    
    private var addButton: some View {
        Button {
            vm.addButtonPressed()
        } label: {
            Text("Add")
                .font(.headline)
                .foregroundColor(.white)
                .frame(height: 55)
                .frame(maxWidth: .infinity)
                .background(Color.pink)
                .cornerRadius(10)
            
        }
    }
}

struct CloudKitCrudView_Previews: PreviewProvider {
    static var previews: some View {
        CloudKitCrudView()
    }
}
