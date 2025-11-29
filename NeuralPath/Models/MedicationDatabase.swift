//
//  MedicationDatabase.swift
//  NeuralPath
//
//  Created by Claude Code
//

import Foundation

struct MedicationInfo: Identifiable {
    let id = UUID()
    let name: String
    let category: MedicationCategory
    let aliases: [String]
}

struct MedicationDatabase {
    static let medications: [MedicationInfo] = [
        // MARK: - SSRIs
        MedicationInfo(name: "Sertraline", category: .ssri, aliases: ["Zoloft"]),
        MedicationInfo(name: "Fluoxetine", category: .ssri, aliases: ["Prozac"]),
        MedicationInfo(name: "Escitalopram", category: .ssri, aliases: ["Lexapro", "Cipralex"]),
        MedicationInfo(name: "Citalopram", category: .ssri, aliases: ["Celexa"]),
        MedicationInfo(name: "Paroxetine", category: .ssri, aliases: ["Paxil", "Seroxat"]),
        MedicationInfo(name: "Fluvoxamine", category: .ssri, aliases: ["Luvox"]),
        MedicationInfo(name: "Vilazodone", category: .ssri, aliases: ["Viibryd"]),

        // MARK: - SNRIs
        MedicationInfo(name: "Venlafaxine", category: .snri, aliases: ["Effexor"]),
        MedicationInfo(name: "Duloxetine", category: .snri, aliases: ["Cymbalta"]),
        MedicationInfo(name: "Desvenlafaxine", category: .snri, aliases: ["Pristiq"]),
        MedicationInfo(name: "Levomilnacipran", category: .snri, aliases: ["Fetzima"]),
        MedicationInfo(name: "Milnacipran", category: .snri, aliases: ["Savella"]),

        // MARK: - TCAs
        MedicationInfo(name: "Amitriptyline", category: .tca, aliases: ["Elavil"]),
        MedicationInfo(name: "Nortriptyline", category: .tca, aliases: ["Pamelor"]),
        MedicationInfo(name: "Imipramine", category: .tca, aliases: ["Tofranil"]),
        MedicationInfo(name: "Desipramine", category: .tca, aliases: ["Norpramin"]),
        MedicationInfo(name: "Clomipramine", category: .tca, aliases: ["Anafranil"]),
        MedicationInfo(name: "Doxepin", category: .tca, aliases: ["Sinequan", "Silenor"]),
        MedicationInfo(name: "Trimipramine", category: .tca, aliases: ["Surmontil"]),
        MedicationInfo(name: "Protriptyline", category: .tca, aliases: ["Vivactil"]),

        // MARK: - Tetracyclics
        MedicationInfo(name: "Maprotiline", category: .tetracyclic, aliases: ["Ludiomil"]),
        MedicationInfo(name: "Amoxapine", category: .tetracyclic, aliases: ["Asendin"]),
        MedicationInfo(name: "Mianserin", category: .tetracyclic, aliases: ["Tolvon"]),

        // MARK: - MAOIs
        MedicationInfo(name: "Phenelzine", category: .maoi, aliases: ["Nardil"]),
        MedicationInfo(name: "Tranylcypromine", category: .maoi, aliases: ["Parnate"]),
        MedicationInfo(name: "Selegiline", category: .maoi, aliases: ["Emsam", "Eldepryl"]),
        MedicationInfo(name: "Isocarboxazid", category: .maoi, aliases: ["Marplan"]),
        MedicationInfo(name: "Moclobemide", category: .maoi, aliases: ["Manerix"]),

        // MARK: - NDRIs
        MedicationInfo(name: "Bupropion", category: .ndri, aliases: ["Wellbutrin", "Zyban", "Aplenzin"]),

        // MARK: - NaSSAs
        MedicationInfo(name: "Mirtazapine", category: .nassa, aliases: ["Remeron"]),

        // MARK: - SARIs
        MedicationInfo(name: "Trazodone", category: .sari, aliases: ["Desyrel", "Oleptro"]),
        MedicationInfo(name: "Nefazodone", category: .sari, aliases: ["Serzone"]),

        // MARK: - SMS
        MedicationInfo(name: "Vortioxetine", category: .sms, aliases: ["Trintellix", "Brintellix"]),

        // MARK: - Melatonergic
        MedicationInfo(name: "Agomelatine", category: .melatonergic, aliases: ["Valdoxan", "Thymanax"]),

        // MARK: - Atypical Antidepressants
        MedicationInfo(name: "Tianeptine", category: .atypicalAntidepressant, aliases: ["Stablon", "Coaxil"]),
        MedicationInfo(name: "Esketamine", category: .atypicalAntidepressant, aliases: ["Spravato"]),
        MedicationInfo(name: "Ketamine", category: .atypicalAntidepressant, aliases: ["Ketalar"]),

        // MARK: - Antipsychotics (Atypical)
        MedicationInfo(name: "Quetiapine", category: .antipsychotic, aliases: ["Seroquel"]),
        MedicationInfo(name: "Aripiprazole", category: .antipsychotic, aliases: ["Abilify"]),
        MedicationInfo(name: "Olanzapine", category: .antipsychotic, aliases: ["Zyprexa"]),
        MedicationInfo(name: "Risperidone", category: .antipsychotic, aliases: ["Risperdal"]),
        MedicationInfo(name: "Ziprasidone", category: .antipsychotic, aliases: ["Geodon"]),
        MedicationInfo(name: "Lurasidone", category: .antipsychotic, aliases: ["Latuda"]),
        MedicationInfo(name: "Cariprazine", category: .antipsychotic, aliases: ["Vraylar"]),
        MedicationInfo(name: "Brexpiprazole", category: .antipsychotic, aliases: ["Rexulti"]),
        MedicationInfo(name: "Clozapine", category: .antipsychotic, aliases: ["Clozaril"]),
        MedicationInfo(name: "Paliperidone", category: .antipsychotic, aliases: ["Invega"]),
        MedicationInfo(name: "Asenapine", category: .antipsychotic, aliases: ["Saphris"]),
        MedicationInfo(name: "Iloperidone", category: .antipsychotic, aliases: ["Fanapt"]),

        // MARK: - Antipsychotics (Typical)
        MedicationInfo(name: "Haloperidol", category: .antipsychotic, aliases: ["Haldol"]),
        MedicationInfo(name: "Chlorpromazine", category: .antipsychotic, aliases: ["Thorazine"]),
        MedicationInfo(name: "Fluphenazine", category: .antipsychotic, aliases: ["Prolixin"]),
        MedicationInfo(name: "Perphenazine", category: .antipsychotic, aliases: ["Trilafon"]),
        MedicationInfo(name: "Thioridazine", category: .antipsychotic, aliases: ["Mellaril"]),
        MedicationInfo(name: "Trifluoperazine", category: .antipsychotic, aliases: ["Stelazine"]),

        // MARK: - Lithium
        MedicationInfo(name: "Lithium Carbonate", category: .lithium, aliases: ["Lithobid", "Eskalith"]),
        MedicationInfo(name: "Lithium Citrate", category: .lithium, aliases: ["Cibalith-S"]),

        // MARK: - Mood Stabilizers
        MedicationInfo(name: "Valproic Acid", category: .moodStabilizer, aliases: ["Depakote", "Depakene", "Valproate"]),
        MedicationInfo(name: "Divalproex", category: .moodStabilizer, aliases: ["Depakote ER"]),
        MedicationInfo(name: "Lamotrigine", category: .moodStabilizer, aliases: ["Lamictal"]),

        // MARK: - Anticonvulsants
        MedicationInfo(name: "Carbamazepine", category: .anticonvulsant, aliases: ["Tegretol", "Carbatrol"]),
        MedicationInfo(name: "Oxcarbazepine", category: .anticonvulsant, aliases: ["Trileptal"]),
        MedicationInfo(name: "Topiramate", category: .anticonvulsant, aliases: ["Topamax"]),
        MedicationInfo(name: "Gabapentin", category: .anticonvulsant, aliases: ["Neurontin", "Gralise"]),
        MedicationInfo(name: "Pregabalin", category: .anticonvulsant, aliases: ["Lyrica"]),
        MedicationInfo(name: "Levetiracetam", category: .anticonvulsant, aliases: ["Keppra"]),
        MedicationInfo(name: "Tiagabine", category: .anticonvulsant, aliases: ["Gabitril"]),

        // MARK: - Benzodiazepines
        MedicationInfo(name: "Alprazolam", category: .benzodiazepine, aliases: ["Xanax"]),
        MedicationInfo(name: "Lorazepam", category: .benzodiazepine, aliases: ["Ativan"]),
        MedicationInfo(name: "Clonazepam", category: .benzodiazepine, aliases: ["Klonopin"]),
        MedicationInfo(name: "Diazepam", category: .benzodiazepine, aliases: ["Valium"]),
        MedicationInfo(name: "Temazepam", category: .benzodiazepine, aliases: ["Restoril"]),
        MedicationInfo(name: "Oxazepam", category: .benzodiazepine, aliases: ["Serax"]),
        MedicationInfo(name: "Chlordiazepoxide", category: .benzodiazepine, aliases: ["Librium"]),
        MedicationInfo(name: "Triazolam", category: .benzodiazepine, aliases: ["Halcion"]),
        MedicationInfo(name: "Flurazepam", category: .benzodiazepine, aliases: ["Dalmane"]),
        MedicationInfo(name: "Midazolam", category: .benzodiazepine, aliases: ["Versed"]),
        MedicationInfo(name: "Clorazepate", category: .benzodiazepine, aliases: ["Tranxene"]),

        // MARK: - Buspirone
        MedicationInfo(name: "Buspirone", category: .buspirone, aliases: ["Buspar"]),

        // MARK: - Sleep Aids
        MedicationInfo(name: "Zolpidem", category: .sleepAid, aliases: ["Ambien", "Ambien CR"]),
        MedicationInfo(name: "Eszopiclone", category: .sleepAid, aliases: ["Lunesta"]),
        MedicationInfo(name: "Zaleplon", category: .sleepAid, aliases: ["Sonata"]),
        MedicationInfo(name: "Suvorexant", category: .sleepAid, aliases: ["Belsomra"]),
        MedicationInfo(name: "Lemborexant", category: .sleepAid, aliases: ["Dayvigo"]),
        MedicationInfo(name: "Daridorexant", category: .sleepAid, aliases: ["Quviviq"]),
        MedicationInfo(name: "Ramelteon", category: .sleepAid, aliases: ["Rozerem"]),
        MedicationInfo(name: "Melatonin", category: .sleepAid, aliases: []),
        MedicationInfo(name: "Tasimelteon", category: .sleepAid, aliases: ["Hetlioz"]),

        // MARK: - Stimulants (ADHD)
        MedicationInfo(name: "Methylphenidate", category: .stimulant, aliases: ["Ritalin", "Concerta", "Daytrana"]),
        MedicationInfo(name: "Amphetamine/Dextroamphetamine", category: .stimulant, aliases: ["Adderall", "Adderall XR"]),
        MedicationInfo(name: "Lisdexamfetamine", category: .stimulant, aliases: ["Vyvanse"]),
        MedicationInfo(name: "Dextroamphetamine", category: .stimulant, aliases: ["Dexedrine", "Zenzedi"]),
        MedicationInfo(name: "Methamphetamine", category: .stimulant, aliases: ["Desoxyn"]),
        MedicationInfo(name: "Modafinil", category: .stimulant, aliases: ["Provigil"]),
        MedicationInfo(name: "Armodafinil", category: .stimulant, aliases: ["Nuvigil"]),

        // MARK: - Non-Stimulant ADHD
        MedicationInfo(name: "Atomoxetine", category: .nonStimulantADHD, aliases: ["Strattera"]),
        MedicationInfo(name: "Guanfacine", category: .nonStimulantADHD, aliases: ["Intuniv", "Tenex"]),
        MedicationInfo(name: "Clonidine", category: .nonStimulantADHD, aliases: ["Kapvay", "Catapres"]),
        MedicationInfo(name: "Viloxazine", category: .nonStimulantADHD, aliases: ["Qelbree"]),

        // MARK: - Beta Blockers
        MedicationInfo(name: "Propranolol", category: .betaBlocker, aliases: ["Inderal", "Hemangeol"]),
        MedicationInfo(name: "Atenolol", category: .betaBlocker, aliases: ["Tenormin"]),
        MedicationInfo(name: "Metoprolol", category: .betaBlocker, aliases: ["Lopressor", "Toprol-XL"]),
        MedicationInfo(name: "Nadolol", category: .betaBlocker, aliases: ["Corgard"]),

        // MARK: - Antihistamines
        MedicationInfo(name: "Hydroxyzine", category: .antihistamine, aliases: ["Vistaril", "Atarax"]),
        MedicationInfo(name: "Diphenhydramine", category: .antihistamine, aliases: ["Benadryl"]),
        MedicationInfo(name: "Promethazine", category: .antihistamine, aliases: ["Phenergan"]),
        MedicationInfo(name: "Cyproheptadine", category: .antihistamine, aliases: ["Periactin"]),

        // MARK: - Opioids
        MedicationInfo(name: "Tramadol", category: .opioid, aliases: ["Ultram"]),
        MedicationInfo(name: "Hydrocodone", category: .opioid, aliases: ["Vicodin", "Norco"]),
        MedicationInfo(name: "Oxycodone", category: .opioid, aliases: ["OxyContin", "Percocet"]),
        MedicationInfo(name: "Morphine", category: .opioid, aliases: ["MS Contin"]),
        MedicationInfo(name: "Buprenorphine", category: .opioid, aliases: ["Subutex", "Suboxone"]),
        MedicationInfo(name: "Methadone", category: .opioid, aliases: ["Dolophine"]),
        MedicationInfo(name: "Naltrexone", category: .opioid, aliases: ["Vivitrol", "ReVia"]),

        // MARK: - NSAIDs
        MedicationInfo(name: "Ibuprofen", category: .nsaid, aliases: ["Advil", "Motrin"]),
        MedicationInfo(name: "Naproxen", category: .nsaid, aliases: ["Aleve", "Naprosyn"]),
        MedicationInfo(name: "Celecoxib", category: .nsaid, aliases: ["Celebrex"]),
        MedicationInfo(name: "Meloxicam", category: .nsaid, aliases: ["Mobic"]),
        MedicationInfo(name: "Diclofenac", category: .nsaid, aliases: ["Voltaren"]),

        // MARK: - Muscle Relaxants
        MedicationInfo(name: "Cyclobenzaprine", category: .muscleRelaxant, aliases: ["Flexeril"]),
        MedicationInfo(name: "Baclofen", category: .muscleRelaxant, aliases: ["Lioresal"]),
        MedicationInfo(name: "Tizanidine", category: .muscleRelaxant, aliases: ["Zanaflex"]),
        MedicationInfo(name: "Methocarbamol", category: .muscleRelaxant, aliases: ["Robaxin"]),
        MedicationInfo(name: "Carisoprodol", category: .muscleRelaxant, aliases: ["Soma"]),

        // MARK: - Thyroid
        MedicationInfo(name: "Levothyroxine", category: .thyroid, aliases: ["Synthroid", "Levoxyl", "Tirosint"]),
        MedicationInfo(name: "Liothyronine", category: .thyroid, aliases: ["Cytomel"]),
        MedicationInfo(name: "Armour Thyroid", category: .thyroid, aliases: ["Desiccated Thyroid"]),
        MedicationInfo(name: "NP Thyroid", category: .thyroid, aliases: []),

        // MARK: - Hormones
        MedicationInfo(name: "Estradiol", category: .hormone, aliases: ["Estrace", "Vivelle"]),
        MedicationInfo(name: "Progesterone", category: .hormone, aliases: ["Prometrium"]),
        MedicationInfo(name: "Testosterone", category: .hormone, aliases: ["AndroGel", "Testim"]),
        MedicationInfo(name: "DHEA", category: .hormone, aliases: []),

        // MARK: - Supplements
        MedicationInfo(name: "Omega-3 Fish Oil", category: .supplement, aliases: ["Fish Oil", "EPA/DHA"]),
        MedicationInfo(name: "Vitamin D", category: .supplement, aliases: ["D3", "Cholecalciferol"]),
        MedicationInfo(name: "Vitamin B12", category: .supplement, aliases: ["Cobalamin", "Methylcobalamin"]),
        MedicationInfo(name: "Folate", category: .supplement, aliases: ["Folic Acid", "L-Methylfolate", "Deplin"]),
        MedicationInfo(name: "Magnesium", category: .supplement, aliases: ["Magnesium Glycinate", "Magnesium Citrate"]),
        MedicationInfo(name: "Zinc", category: .supplement, aliases: []),
        MedicationInfo(name: "Iron", category: .supplement, aliases: ["Ferrous Sulfate"]),
        MedicationInfo(name: "SAMe", category: .supplement, aliases: ["S-Adenosylmethionine"]),
        MedicationInfo(name: "St. John's Wort", category: .supplement, aliases: ["Hypericum"]),
        MedicationInfo(name: "L-Theanine", category: .supplement, aliases: []),
        MedicationInfo(name: "5-HTP", category: .supplement, aliases: ["5-Hydroxytryptophan"]),
        MedicationInfo(name: "Ashwagandha", category: .supplement, aliases: ["Withania somnifera"]),
        MedicationInfo(name: "Valerian Root", category: .supplement, aliases: []),
        MedicationInfo(name: "Rhodiola Rosea", category: .supplement, aliases: ["Golden Root"]),
        MedicationInfo(name: "NAC", category: .supplement, aliases: ["N-Acetyl Cysteine"]),
        MedicationInfo(name: "Inositol", category: .supplement, aliases: []),
        MedicationInfo(name: "Phosphatidylserine", category: .supplement, aliases: []),
        MedicationInfo(name: "CBD Oil", category: .supplement, aliases: ["Cannabidiol"]),

        // MARK: - Cardiovascular
        MedicationInfo(name: "Lisinopril", category: .cardiovascular, aliases: ["Zestril", "Prinivil"]),
        MedicationInfo(name: "Amlodipine", category: .cardiovascular, aliases: ["Norvasc"]),
        MedicationInfo(name: "Losartan", category: .cardiovascular, aliases: ["Cozaar"]),
        MedicationInfo(name: "Hydrochlorothiazide", category: .cardiovascular, aliases: ["HCTZ"]),

        // MARK: - Diabetes
        MedicationInfo(name: "Metformin", category: .diabetes, aliases: ["Glucophage"]),
        MedicationInfo(name: "Semaglutide", category: .diabetes, aliases: ["Ozempic", "Wegovy"]),
        MedicationInfo(name: "Liraglutide", category: .diabetes, aliases: ["Victoza", "Saxenda"]),
    ]

    static func search(_ query: String) -> [MedicationInfo] {
        guard !query.isEmpty else { return medications }
        let lowercased = query.lowercased()
        return medications.filter { med in
            med.name.lowercased().contains(lowercased) ||
            med.aliases.contains { $0.lowercased().contains(lowercased) }
        }
    }

    static func byCategory(_ category: MedicationCategory) -> [MedicationInfo] {
        medications.filter { $0.category == category }
    }

    static var sortedByName: [MedicationInfo] {
        medications.sorted { $0.name < $1.name }
    }
}
