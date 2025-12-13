//
//  OnboardingFlowView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 10/12/2025.
//

import SwiftUI

private struct OnboardingData {
    var name: String = ""
    var gender: String = ""
    var age: Int? = nil
    var heightCm: Double? = nil
    var weightKg: Double? = nil
    var trainingGoal: TrainingGoal? = nil
    var trainingDaysPerWeek: Int? = nil       // NEW
    var trainingExperience: TrainingExperience? = nil
    var trainingStyle: TrainingStyle? = nil
    var trainingTimeOfDay: TrainingTimeOfDay? = nil
    var nonTrainingActivityLevel: NonTrainingActivityLevel? = nil
}

private enum OnboardingStep {
    case name
    case gender
    case age
    case height
    case weight
    case trainingDays
    case experience
    case trainingStyle
    case trainingTime
    case activityLevel
    case goal
}



struct OnboardingFlowView: View {
    /// Called when the last step finishes successfully.
    let onFinished: (String, String, Int, Double, Double, TrainingGoal, Int, TrainingExperience, TrainingStyle, TrainingTimeOfDay, NonTrainingActivityLevel) -> Void
    
    @State private var data = OnboardingData()
    @State private var step: OnboardingStep = .name
    
    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case .name:
                    OnboardingNameStepView(
                        onNext: {
                            step = .gender
                        }, name: $data.name
                    )
                    
                case .gender:
                    OnboardingGenderStepView(
                        name: data.name,
                        gender: $data.gender,
                        onNext: {
                            step = .age
                        }, onBack: {
                            step = .name
                        }
                    )
                    
                case .age:
                    OnboardingAgeStepView(age: $data.age, onBack: {
                        step = .gender
                    }, onNext: {
                        step = .height
                    })
                    
                case .height:
                    OnboardingHeightStepView(heightCm: $data.heightCm, onBack: {
                        step = .gender
                    }, onNext: { step = .weight })
                    
                case .weight:
                    OnboardingWeightStepView(weightKg: $data.weightKg, onBack: { step = .height }, onNext: { step = .trainingDays })
                    
                case .trainingDays:
                    OnboardingTrainingDaysStepView(trainingDaysPerWeek: $data.trainingDaysPerWeek, onBack: {
                        step = .weight
                    }, onNext: {
                        step = .experience
                    })
                    
                case .experience:
                    OnboardingTrainingExperienceStepView(selectedExperience: $data.trainingExperience, onBack: { step = .trainingDays }, onNext: { step = .trainingStyle })
                
                case .trainingStyle:
                    OnboardingTrainingStyleStepView(selectedStyle: $data.trainingStyle, onBack: { step = .experience}, onNext: { step = .trainingTime })
                    
                case .trainingTime:
                    OnboardingTrainingTimeStepView(selectedTime: $data.trainingTimeOfDay, onBack: { step = .trainingStyle }, onNext: { step = .activityLevel })
                    
                case .activityLevel:
                    OnboardingActivityLevelStepView(selectedLevel: $data.nonTrainingActivityLevel, onBack: { step = .trainingTime }, onNext: { step = .goal })
                case .goal:
                    OnboardingTrainingGoalStepView(selectedGoal: $data.trainingGoal, onBack: { step = .trainingStyle }, onFinish: {
                        guard
                            let age = data.age,
                            let height = data.heightCm,
                            let weight = data.weightKg,
                            let goal = data.trainingGoal,
                            let days = data.trainingDaysPerWeek,
                            let experience = data.trainingExperience,
                            let style = data.trainingStyle,
                            let trainingTime = data.trainingTimeOfDay,
                            let activityLevel = data.nonTrainingActivityLevel
                            
                        else { return }
                        onFinished(data.name, data.gender, age, height, weight, goal, days, experience, style, trainingTime, activityLevel)
                    })
                }
            }
        }
    }
}

#Preview {
    OnboardingFlowView { name, gender, age, height, weight, trainingGoal, trainingDays, trainingExperience, trainingStyle, trainingTime, activityLevel in
        print("Finished onboarding with:", name, gender, age, height, weight, trainingGoal, trainingDays, trainingExperience, trainingStyle, trainingTime, activityLevel)
    }
}
