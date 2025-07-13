import HashMap "mo:base/HashMap";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Array "mo:base/Array";
import Float "mo:base/Float";
import Iter "mo:base/Iter";

actor CarbonTracker {
    
    // Simple data types
    type Activity = {
        description: Text;
        carbon: Float;
        timestamp: Int;
    };
    
    type ChatResponse = {
        message: Text;
        carbonAdded: Float;
        dailyTotal: Float;
    };
    
    // Storage
    private stable var activitiesEntries: [(Text, [Activity])] = [];
    private var activities = HashMap.fromIter<Text, [Activity]>(activitiesEntries.vals(), 10, Text.equal, Text.hash);
    
    // Carbon factors database
    private let carbonFactors = HashMap.fromIter<Text, Float>([
        ("motor", 0.12), ("mobil", 0.21), ("ojol", 0.15), ("grab", 0.18),
        ("angkot", 0.08), ("busway", 0.04), ("kereta", 0.03), ("sepeda", 0.0),
        ("nasi", 1.8), ("ayam", 2.5), ("warteg", 2.0), ("padang", 3.2),
        ("mcd", 4.5), ("vegetarian", 1.2), ("ac", 0.8), ("tv", 0.15),
        ("komputer", 0.3), ("kulkas", 0.1)
    ].vals(), 20, Text.equal, Text.hash);
    
    // Simple keyword matching (fixed)
    private func calculateCarbon(text: Text) : (Float, Text) {
        var totalCarbon: Float = 0;
        var foundActivity = "";
        
        // Check each carbon factor
        for ((key, value) in carbonFactors.entries()) {
            if (Text.contains(text, #text key)) {
                totalCarbon += value;
                foundActivity := key;
            };
        };
        
        // Extract numbers for distance/duration
        var multiplier: Float = 1.0;
        if (Text.contains(text, #text "km")) {
            multiplier := 10.0; // assume 10km if "km" mentioned
        };
        if (Text.contains(text, #text "jam")) {
            multiplier := 8.0; // assume 8 hours if "jam" mentioned
        };
        
        if (totalCarbon == 0) {
            (2.0, "aktivitas umum") // default
        } else {
            (totalCarbon * multiplier, foundActivity)
        }
    };
    
    // Main chat function
    public func processActivity(userId: Text, input: Text) : async ChatResponse {
        let (carbon, activity) = calculateCarbon(input);
        let now = Time.now();
        
        let newActivity: Activity = {
            description = input;
            carbon = carbon;
            timestamp = now;
        };
        
        // Get existing activities
        let existingActivities = switch (activities.get(userId)) {
            case null { [] };
            case (?acts) { acts };
        };
        
        // Add new activity
        let updatedActivities = Array.append(existingActivities, [newActivity]);
        activities.put(userId, updatedActivities);
        
        // Calculate daily total
        let dailyTotal = Array.foldLeft<Activity, Float>(
            updatedActivities, 
            0, 
            func(acc, act) { acc + act.carbon }
        );
        
        // Generate response
        let responseMessage = "✅ " # activity # " dicatat! Total hari ini: " # Float.toText(dailyTotal) # " kg CO2";
        
        {
            message = responseMessage;
            carbonAdded = carbon;
            dailyTotal = dailyTotal;
        }
    };
    
    // Get daily total
    public query func getDailyCarbon(userId: Text) : async Float {
        switch (activities.get(userId)) {
            case null { 0 };
            case (?acts) {
                Array.foldLeft<Activity, Float>(acts, 0, func(acc, act) { acc + act.carbon })
            };
        }
    };
    
    // Get activities
    public query func getActivities(userId: Text) : async [Activity] {
        switch (activities.get(userId)) {
            case null { [] };
            case (?acts) { acts };
        }
    };
    
    // Reset daily activities
    public func resetDaily(userId: Text) : async Bool {
        activities.put(userId, []);
        true
    };
    
    // System functions
    system func preupgrade() {
        activitiesEntries := Iter.toArray(activities.entries());
    };
    
    system func postupgrade() {
        activitiesEntries := [];
    };
}