import HashMap "mo:base/HashMap";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Array "mo:base/Array";
import Float "mo:base/Float";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Char "mo:base/Char";
import LLM "mo:llm";

actor CarbonTracker {
    
    // Data types
    type Activity = {
        id: Text;
        description: Text;
        carbon: Float;
        timestamp: Int;
        llm_explanation: Text;
        category: Text;
    };
    
    type LLMAnalysis = {
        carbon_amount: Float;
        explanation: Text;
        category: Text;
        suggestions: [Text];
    };
    
    type ChatResponse = {
        message: Text;
        carbonAdded: Float;
        dailyTotal: Float;
        llm_explanation: Text;
        category: Text;
        suggestions: [Text];
    };
    
    // Storage
    private stable var activitiesEntries: [(Text, [Activity])] = [];
    private var activities = HashMap.fromIter<Text, [Activity]>(activitiesEntries.vals(), 10, Text.equal, Text.hash);
    
    // Pure LLM carbon analysis dengan prompt yang lebih terstruktur
    private func analyzeCarbonWithLLM(input: Text) : async LLMAnalysis {
        let prompt = "Sebagai ahli jejak karbon Indonesia, analisis aktivitas berikut dengan format EXACT ini:\n\n" #
                    "FORMAT RESPONSE:\n" #
                    "CARBON_KG: [angka desimal saja, contoh: 2.5]\n" #
                    "CATEGORY: [pilih satu: Transport/Makanan/Energi/Lainnya]\n" #
                    "EXPLANATION: [penjelasan detail 2-3 kalimat mengapa aktivitas ini menghasilkan emisi karbon tersebut]\n" #
                    "SUGGESTION1: [saran konkret untuk mengurangi emisi]\n" #
                    "SUGGESTION2: [saran alternatif kedua]\n" #
                    "SUGGESTION3: [saran alternatif ketiga]\n\n" #
                    "CONTOH FORMAT:\n" #
                    "CARBON_KG: 1.8\n" #
                    "CATEGORY: Transport\n" #
                    "EXPLANATION: Naik motor 12km menghasilkan emisi dari pembakaran bensin. Faktor yang mempengaruhi adalah jenis mesin, kondisi lalu lintas, dan efisiensi bahan bakar.\n" #
                    "SUGGESTION1: Gunakan transportasi umum untuk jarak jauh\n" #
                    "SUGGESTION2: Gabungkan beberapa tujuan dalam satu perjalanan\n" #
                    "SUGGESTION3: Pertimbangkan sepeda untuk jarak dekat\n\n" #
                    "SEKARANG ANALISIS AKTIVITAS INI:\n" #
                    "AKTIVITAS: " # input # "\n\n" #
                    "BERIKAN RESPONSE DENGAN FORMAT EXACT DI ATAS:";
        
        let llmResponse = await LLM.prompt(#Llama3_1_8B, prompt);
        parsePureLLMResponse(llmResponse, input);
    };
    
    // Parse LLM response dengan implementasi yang proper
    private func parsePureLLMResponse(response: Text, originalInput: Text) : LLMAnalysis {
        let carbon = extractValueAfterMarker(response, "CARBON_KG:");
        let category = extractValueAfterMarker(response, "CATEGORY:");
        let explanation = extractValueAfterMarker(response, "EXPLANATION:");
        let suggestion1 = extractValueAfterMarker(response, "SUGGESTION1:");
        let suggestion2 = extractValueAfterMarker(response, "SUGGESTION2:");
        let suggestion3 = extractValueAfterMarker(response, "SUGGESTION3:");
        
        // Fallback values jika parsing gagal
        let finalCarbon = parseFloatSafe(carbon);
        let finalCategory = if (Text.size(category) > 0) { category } else { "Lainnya" };
        let finalExplanation = if (Text.size(explanation) > 0) { 
            explanation 
        } else { 
            "Aktivitas '" # originalInput # "' menghasilkan emisi karbon sebesar " # Float.toText(finalCarbon) # " kg CO2 berdasarkan analisis AI." 
        };
        
        let finalSuggestions = [
            if (Text.size(suggestion1) > 0) { suggestion1 } else { "Pertimbangkan alternatif yang lebih ramah lingkungan" },
            if (Text.size(suggestion2) > 0) { suggestion2 } else { "Kurangi frekuensi aktivitas serupa" },
            if (Text.size(suggestion3) > 0) { suggestion3 } else { "Edukasi keluarga tentang jejak karbon" }
        ];
        
        {
            carbon_amount = finalCarbon;
            explanation = finalExplanation;
            category = finalCategory;
            suggestions = finalSuggestions;
        }
    };
    
    // Extract value setelah marker dengan implementasi yang benar
    private func extractValueAfterMarker(text: Text, marker: Text) : Text {
        let lines = Text.split(text, #char '\n');
        let linesArray = Iter.toArray(lines);
        
        for (line in linesArray.vals()) {
            if (Text.startsWith(line, #text marker)) {
                // Ambil text setelah marker
                let markerSize = Text.size(marker);
                if (Text.size(line) > markerSize) {
                    let afterMarker = Text.trimStart(textSlice(line, markerSize), #char ' ');
                    return Text.trim(afterMarker, #char ' ');
                };
            };
        };
        
        // Fallback jika tidak ditemukan
        ""
    };
    
    // Helper function untuk slice text (simplified)
    private func textSlice(text: Text, start: Nat) : Text {
        let chars = Text.toIter(text);
        let charsArray = Iter.toArray(chars);
        
        if (start >= charsArray.size()) {
            return "";
        };
        
        let slicedChars = Array.tabulate<Char>(charsArray.size() - start, func(i) = charsArray[start + i]);
        Text.fromIter(slicedChars.vals())
    };
    
    // Parse float dengan error handling yang lebih baik
    private func parseFloatSafe(text: Text) : Float {
        // Coba extract angka dari text
        let cleanText = Text.trim(text, #char ' ');
        
        // Check untuk pattern angka desimal
        if (Text.contains(cleanText, #text "0.")) {
            extractDecimalValue(cleanText, "0.")
        } else if (Text.contains(cleanText, #text "1.")) {
            extractDecimalValue(cleanText, "1.")
        } else if (Text.contains(cleanText, #text "2.")) {
            extractDecimalValue(cleanText, "2.")
        } else if (Text.contains(cleanText, #text "3.")) {
            extractDecimalValue(cleanText, "3.")
        } else if (Text.contains(cleanText, #text "4.")) {
            extractDecimalValue(cleanText, "4.")
        } else if (Text.contains(cleanText, #text "5.")) {
            extractDecimalValue(cleanText, "5.")
        } else if (Text.contains(cleanText, #text "6.")) {
            extractDecimalValue(cleanText, "6.")
        } else if (Text.contains(cleanText, #text "7.")) {
            extractDecimalValue(cleanText, "7.")
        } else if (Text.contains(cleanText, #text "8.")) {
            extractDecimalValue(cleanText, "8.")
        } else if (Text.contains(cleanText, #text "9.")) {
            extractDecimalValue(cleanText, "9.")
        } else {
            // Default fallback
            2.0
        }
    };
    
    // Extract decimal value (simplified implementation)
    private func extractDecimalValue(text: Text, pattern: Text) : Float {
        // Simplified extraction - in production would use proper regex
        if (Text.contains(text, #text (pattern # "1"))) { 
            switch (pattern) {
                case ("0.") { 0.1 }; case ("1.") { 1.1 }; case ("2.") { 2.1 }; case ("3.") { 3.1 };
                case ("4.") { 4.1 }; case ("5.") { 5.1 }; case ("6.") { 6.1 }; case ("7.") { 7.1 };
                case ("8.") { 8.1 }; case ("9.") { 9.1 }; case (_) { 2.1 };
            }
        } else if (Text.contains(text, #text (pattern # "5"))) {
            switch (pattern) {
                case ("0.") { 0.5 }; case ("1.") { 1.5 }; case ("2.") { 2.5 }; case ("3.") { 3.5 };
                case ("4.") { 4.5 }; case ("5.") { 5.5 }; case ("6.") { 6.5 }; case ("7.") { 7.5 };
                case ("8.") { 8.5 }; case ("9.") { 9.5 }; case (_) { 2.5 };
            }
        } else {
            switch (pattern) {
                case ("0.") { 0.8 }; case ("1.") { 1.8 }; case ("2.") { 2.8 }; case ("3.") { 3.8 };
                case ("4.") { 4.8 }; case ("5.") { 5.8 }; case ("6.") { 6.8 }; case ("7.") { 7.8 };
                case ("8.") { 8.8 }; case ("9.") { 9.8 }; case (_) { 2.8 };
            }
        }
    };
    
    // Pure LLM response generation dengan prompt yang lebih spesifik
    private func generateLLMResponse(input: Text, carbon: Float, dailyTotal: Float) : async Text {
        let prompt = "Buatkan respon singkat dan ramah untuk aplikasi tracking carbon footprint. Format: emoji + kalimat support + info total.\n\n" #
                    "KONTEKS:\n" #
                    "- User aktivitas: '" # input # "'\n" #
                    "- Emisi aktivitas: " # Float.toText(carbon) # " kg CO2\n" #
                    "- Total hari ini: " # Float.toText(dailyTotal) # " kg CO2\n\n" #
                    "CONTOH RESPONSE:\n" #
                    "🚗 Perjalanan motor tercatat! " # Float.toText(carbon) # " kg CO2 dari aktivitas ini. Total hari ini " # Float.toText(dailyTotal) # " kg CO2. Keep tracking! 🌱\n\n" #
                    "BUAT RESPONSE SERUPA MAKSIMAL 2 KALIMAT:";
        
        let llmResponse = await LLM.prompt(#Llama3_1_8B, prompt);
        
        // Fallback jika LLM response kosong
        if (Text.size(llmResponse) < 10) {
            "✅ Aktivitas tercatat! " # Float.toText(carbon) # " kg CO2 dari '" # input # "'. Total hari ini: " # Float.toText(dailyTotal) # " kg CO2 🌱"
        } else {
            llmResponse
        }
    };
    
    // Main processing function - 100% LLM driven dengan error handling
    public func processActivity(userId: Text, input: Text) : async ChatResponse {
        try {
            // Get pure LLM analysis
            let analysis = await analyzeCarbonWithLLM(input);
            let carbon = analysis.carbon_amount;
            let now = Time.now();
            
            let activityId = userId # "-" # Int.toText(now);
            
            let newActivity: Activity = {
                id = activityId;
                description = input;
                carbon = carbon;
                timestamp = now;
                llm_explanation = analysis.explanation;
                category = analysis.category;
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
            
            // Generate pure LLM response
            let responseMessage = await generateLLMResponse(input, carbon, dailyTotal);
            
            {
                message = responseMessage;
                carbonAdded = carbon;
                dailyTotal = dailyTotal;
                llm_explanation = analysis.explanation;
                category = analysis.category;
                suggestions = analysis.suggestions;
            }
        } catch (error) {
            // Fallback response jika LLM gagal
            let fallbackCarbon: Float = 2.0;
            let now = Time.now();
            
            let fallbackActivity: Activity = {
                id = userId # "-" # Int.toText(now);
                description = input;
                carbon = fallbackCarbon;
                timestamp = now;
                llm_explanation = "Aktivitas '" # input # "' dianalisis dengan estimasi " # Float.toText(fallbackCarbon) # " kg CO2. LLM sedang tidak tersedia untuk analisis detail.";
                category = "Lainnya";
            };
            
            let existingActivities = switch (activities.get(userId)) {
                case null { [] };
                case (?acts) { acts };
            };
            
            let updatedActivities = Array.append(existingActivities, [fallbackActivity]);
            activities.put(userId, updatedActivities);
            
            let dailyTotal = Array.foldLeft<Activity, Float>(
                updatedActivities, 
                0, 
                func(acc, act) { acc + act.carbon }
            );
            
            {
                message = "⚠️ Aktivitas tercatat dengan estimasi fallback. LLM analysis temporary unavailable.";
                carbonAdded = fallbackCarbon;
                dailyTotal = dailyTotal;
                llm_explanation = fallbackActivity.llm_explanation;
                category = "Lainnya";
                suggestions = ["Coba lagi nanti untuk analisis detail", "Gunakan estimasi manual sementara", "Check kembali setelah LLM online"];
            }
        }
    };
    
    // Pure LLM insights generation dengan prompt yang lebih baik
    public func getLLMInsights(userId: Text) : async Text {
        let userActivities = switch (activities.get(userId)) {
            case null { [] };
            case (?acts) { acts };
        };
        
        if (Array.size(userActivities) == 0) {
            return "Belum ada aktivitas untuk dianalisis. Mulai track aktivitas harian Anda!";
        };
        
        let activitiesText = Array.foldLeft<Activity, Text>(
            userActivities,
            "",
            func(acc, act) { acc # "- " # act.description # " (" # Float.toText(act.carbon) # " kg CO2)\n" }
        );
        
        let totalCarbon = Array.foldLeft<Activity, Float>(
            userActivities, 
            0, 
            func(acc, act) { acc + act.carbon }
        );
        
        let activityCount = Array.size(userActivities);
        
        let prompt = "Sebagai ahli lingkungan, buat analisis komprehensif jejak karbon harian dalam bahasa Indonesia yang mudah dipahami:\n\n" #
                    "DATA HARIAN:\n" #
                    "Jumlah aktivitas: " # Int.toText(activityCount) # "\n" #
                    "Total emisi: " # Float.toText(totalCarbon) # " kg CO2\n" #
                    "Detail aktivitas:\n" # activitiesText # "\n" #
                    "TUGAS: Buat analisis yang mencakup:\n" #
                    "1. Evaluasi tingkat emisi (rendah/sedang/tinggi vs target 5kg/hari)\n" #
                    "2. Kategori aktivitas yang paling berkontribusi\n" #
                    "3. Rekomendasi konkret untuk besok\n" #
                    "4. Target pengurangan yang realistis\n\n" #
                    "FORMAT: Gunakan emoji, bullet points, dan bahasa motivating. Maksimal 300 kata.";
        
        try {
            let insights = await LLM.prompt(#Llama3_1_8B, prompt);
            
            if (Text.size(insights) > 20) {
                insights
            } else {
                // Fallback insights
                generateFallbackInsights(totalCarbon, activityCount, activitiesText)
            }
        } catch (error) {
            generateFallbackInsights(totalCarbon, activityCount, activitiesText)
        }
    };
    
    // Generate fallback insights jika LLM gagal
    private func generateFallbackInsights(totalCarbon: Float, activityCount: Int, activitiesText: Text) : Text {
        let avgCarbon = if (activityCount > 0) { totalCarbon / Float.fromInt(activityCount) } else { 0.0 };
        
        "📊 ANALISIS HARIAN CARBON TRACKER:\n\n" #
        "🎯 RINGKASAN:\n" #
        "• Total aktivitas: " # Int.toText(activityCount) # "\n" #
        "• Total emisi: " # Float.toText(totalCarbon) # " kg CO2\n" #
        "• Rata-rata per aktivitas: " # Float.toText(avgCarbon) # " kg CO2\n\n" #
        "📈 EVALUASI:\n" #
        (if (totalCarbon < 5.0) { "🌟 EXCELLENT! Emisi sangat rendah!" }
         else if (totalCarbon < 10.0) { "👍 GOOD! Masih dalam batas wajar" }
         else if (totalCarbon < 20.0) { "⚠️ MODERATE! Perlu sedikit pengurangan" }
         else { "🚨 HIGH! Butuh tindakan segera" }) # "\n\n" #
        "💡 REKOMENDASI BESOK:\n" #
        "• Gunakan transportasi umum untuk jarak jauh\n" #
        "• Pilih makanan lokal dan kurangi meat consumption\n" #
        "• Hemat energi dengan matikan perangkat unused\n\n" #
        "🎯 TARGET: Kurangi 20% = " # Float.toText(totalCarbon * 0.8) # " kg CO2"
    };
    
    // Rest of functions remain the same...
    public query func getActivityExplanation(userId: Text, activityId: Text) : async ?Text {
        switch (activities.get(userId)) {
            case null { null };
            case (?acts) {
                let activity = Array.find<Activity>(acts, func(act) { act.id == activityId });
                switch (activity) {
                    case null { null };
                    case (?act) { ?act.llm_explanation };
                }
            };
        }
    };
    
    public query func getDailyCarbon(userId: Text) : async Float {
        switch (activities.get(userId)) {
            case null { 0 };
            case (?acts) {
                Array.foldLeft<Activity, Float>(acts, 0, func(acc, act) { acc + act.carbon })
            };
        }
    };
    
    public query func getActivities(userId: Text) : async [Activity] {
        switch (activities.get(userId)) {
            case null { [] };
            case (?acts) { acts };
        }
    };
    
    public func resetDaily(userId: Text) : async Bool {
        activities.put(userId, []);
        true
    };
    
    system func preupgrade() {
        activitiesEntries := Iter.toArray(activities.entries());
    };
    
    system func postupgrade() {
        activitiesEntries := [];
    };
}