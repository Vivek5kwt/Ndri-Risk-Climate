import '../../logic/risk_assessment/bloc/risk_assessment_state.dart';
import '../models/question_model.dart';

class QuestionRepository {
  static List<QuestionModel> getQuestions() {
    return [
      QuestionModel(
        variableNumber: '1',
        questionText: 'Gender of household head',
        questionType: QuestionType.general,
        category: 'Demographic',
      ),
      QuestionModel(
        variableNumber: '2',
        questionText: 'Age (in years)',
        questionType: QuestionType.vulnerability,
        category: 'Demographic',
      ),
      QuestionModel(
        variableNumber: '3',
        questionText: 'Educational qualification of household head',
        questionType: QuestionType.vulnerability,
        category: 'Demographic',
      ),
      QuestionModel(
        variableNumber: '4',
        questionText: 'Total family members in the household',
        questionType: QuestionType.exposure,
        category: 'Demographic',
      ),
      QuestionModel(
        variableNumber: '5',
        questionText: 'Number of working members in the family',
        questionType: QuestionType.exposure,
        category: 'Demographic',
      ),
      QuestionModel(
        variableNumber: '6',
        questionText: 'Number of women in the family (aged 15–69 years)',
        questionType: QuestionType.exposure,
        category: 'Demographic',
      ),
      QuestionModel(
        variableNumber: '7',
        questionText: 'Number of children in the family (aged below 14 years)',
        questionType: QuestionType.exposure,
        category: 'Demographic',
      ),
      QuestionModel(
        variableNumber: '8',
        questionText: 'Number of elderly in the family (aged above 70 years)',
        questionType: QuestionType.exposure,
        category: 'Demographic',
      ),
      QuestionModel(
        variableNumber: '9',
        questionText:
            'Family health history:\nHow many family members have a long-term illness?',
        questionType: QuestionType.exposure,
        category: 'Demographic',
      ),
      QuestionModel(
        variableNumber: '10',
        questionText: 'Condition of household',
        questionType: QuestionType.exposure,
        category: 'Demographic',
      ),
      QuestionModel(
        variableNumber: '11',
        questionText: 'Experience in animal care (in years)',
        questionType: QuestionType.vulnerability,
        category: 'Demographic',
      ),
      QuestionModel(
        variableNumber: '12',
        questionText:
            ' How many years of experience do you have in crop farming?',
        questionType: QuestionType.vulnerability,
        category: 'Agriculture & Dairying',
      ),
      QuestionModel(
        variableNumber: '13',
        questionText: 'Operational Land Holding',
        questionType: QuestionType.vulnerability,
        category: 'Agriculture & Dairying',
      ),
      QuestionModel(
        variableNumber: '13.1',
        questionText: 'Owned land (in acres)',
        questionType: QuestionType.vulnerability,
        category: 'Agriculture & Dairying',
      ),
      QuestionModel(
        variableNumber: '13.2',
        questionText: 'Leased in land (in acres)',
        questionType: QuestionType.vulnerability,
        category: 'Agriculture & Dairying',
      ),
      QuestionModel(
        variableNumber: '13.3',
        questionText: 'Leased out land (in acres)',
        questionType: QuestionType.vulnerability,
        category: 'Agriculture & Dairying',
      ),
      QuestionModel(
        variableNumber: '14',
        questionText: 'Net sown area (in acres)',
        questionType: QuestionType.vulnerability,
        category: 'Agriculture & Dairying',
      ),
      QuestionModel(
        variableNumber: '15',
        questionText: 'Area under irrigation (in acres)',
        questionType: QuestionType.vulnerability,
        category: 'Agriculture & Dairying',
      ),
      QuestionModel(
        variableNumber: '16',
        questionText: 'Productivity of Rice (in Quintals/acre)',
        questionType: QuestionType.vulnerability,
        category: 'Agriculture & Dairying',
      ),
      QuestionModel(
        variableNumber: '17',
        questionText: 'Productivity of Wheat (in Quintals/acre)',
        questionType: QuestionType.vulnerability,
        category: 'Agriculture & Dairying',
      ),
      QuestionModel(
        variableNumber: '18',
        questionText: 'Herd Size (in number)',
        questionType: QuestionType.vulnerability,
        category: 'Agriculture & Dairying',
      ),
      QuestionModel(
        variableNumber: '18.1',
        questionText: 'How many indigenous cattle are currently giving milk?',
        questionType: QuestionType.vulnerability,
        category: 'Agriculture & Dairying',
      ),
      QuestionModel(
        variableNumber: '18.2',
        questionText:
            ' How many indigenous cattle are currently dry (not giving milk)?',
        questionType: QuestionType.vulnerability,
        category: 'Agriculture & Dairying',
      ),
      QuestionModel(
        variableNumber: '18.3',
        questionText:
            'How many young female indigenous cattle (heifers) do you have?',
        questionType: QuestionType.vulnerability,
        category: 'Agriculture & Dairying',
      ),
      QuestionModel(
        variableNumber: '18.4',
        questionText: ' How many indigenous cattle calves do you have?',
        questionType: QuestionType.vulnerability,
        category: 'Agriculture & Dairying',
      ),
      QuestionModel(
        variableNumber: '18.5',
        questionText: 'How many indigenous cattle are currently pregnant?',
        questionType: QuestionType.vulnerability,
        category: 'Agriculture & Dairying',
      ),
      QuestionModel(
        variableNumber: '18.6',
        questionText: 'How many adult male indigenous cattle do you have?',
        questionType: QuestionType.vulnerability,
        category: 'Agriculture & Dairying',
      ),
      QuestionModel(
        variableNumber: '18.7',
        questionText: 'How many crossbred cattle are currently giving milk?',
        questionType: QuestionType.vulnerability,
        category: 'Agriculture & Dairying',
      ),
      QuestionModel(
        variableNumber: '18.8',
        questionText:
            'How many crossbred cattle are currently dry (not giving milk)?',
        questionType: QuestionType.vulnerability,
        category: 'Agriculture & Dairying',
      ),
      QuestionModel(
        variableNumber: '18.9',
        questionText:
            'How many young female crossbred cattle (heifers) do you have?',
        questionType: QuestionType.vulnerability,
        category: 'Agriculture & Dairying',
      ),
      QuestionModel(
        variableNumber: '18.10',
        questionText: 'How many crossbred cattle calves do you have?',
        questionType: QuestionType.vulnerability,
        category: 'Agriculture & Dairying',
      ),
      QuestionModel(
        variableNumber: '18.11',
        questionText: ' How many crossbred cattle are currently pregnant?',
        questionType: QuestionType.vulnerability,
        category: 'Agriculture & Dairying',
      ),
      QuestionModel(
        variableNumber: '18.12',
        questionText: ' How many adult male crossbred cattle do you have?',
        questionType: QuestionType.vulnerability,
        category: 'Agriculture & Dairying',
      ),
      QuestionModel(
        variableNumber: '18.13',
        questionText: 'How many buffaloes are currently giving milk?',
        questionType: QuestionType.vulnerability,
        category: 'Agriculture & Dairying',
      ),
      QuestionModel(
        variableNumber: '18.14',
        questionText: 'How many buffaloes are currently dry (not giving milk)?',
        questionType: QuestionType.vulnerability,
        category: 'Agriculture & Dairying',
      ),
      QuestionModel(
        variableNumber: '18.15',
        questionText: 'How many young female buffaloes (heifers) do you have?',
        questionType: QuestionType.vulnerability,
        category: 'Agriculture & Dairying',
      ),
      QuestionModel(
        variableNumber: '18.16',
        questionText: 'How many buffalo calves do you have?',
        questionType: QuestionType.vulnerability,
        category: 'Agriculture & Dairying',
      ),
      QuestionModel(
        variableNumber: '18.17',
        questionText: 'How many buffaloes are currently pregnant?',
        questionType: QuestionType.vulnerability,
        category: 'Agriculture & Dairying',
      ),
      QuestionModel(
        variableNumber: '18.18',
        questionText: ' How many adult male buffaloes do you have?',
        questionType: QuestionType.vulnerability,
        category: 'Agriculture & Dairying',
      ),
      QuestionModel(
        variableNumber: '19',
        questionText: 'How many animals are suffering from any disease?',
        questionType: QuestionType.vulnerability,
        category: 'Agriculture & Dairying',
      ),
      QuestionModel(
        variableNumber: '20',
        questionText:
            'Disease profile in the herd (Tap on types of diseases which are existing in the herd)',
        questionType: QuestionType.vulnerability,
        category: 'Agriculture & Dairying',
      ),
      QuestionModel(
        variableNumber: '21',
        questionText: 'Daily milk yield of buffaloes in summer (liter/day)',
        questionType: QuestionType.vulnerability,
        category: 'Agriculture & Dairying',
      ),
      QuestionModel(
        variableNumber: '22',
        questionText: 'Daily milk yield of buffaloes in winter (liter/day)',
        questionType: QuestionType.vulnerability,
        category: 'Agriculture & Dairying',
      ),
      QuestionModel(
        variableNumber: '23',
        questionText:
            'Daily milk yield of indigenous cattle in summer(liter/day)',
        questionType: QuestionType.vulnerability,
        category: 'Agriculture & Dairying',
      ),
      QuestionModel(
        variableNumber: '24',
        questionText:
            'Daily milk yield of indigenous cattle in winter(liter/day)',
        questionType: QuestionType.vulnerability,
        category: 'Agriculture & Dairying',
      ),
      QuestionModel(
        variableNumber: '25',
        questionText:
            'Daily milk yield of crossbred cattle in summer(liter/day)',
        questionType: QuestionType.vulnerability,
        category: 'Agriculture & Dairying',
      ),
      QuestionModel(
        variableNumber: '26',
        questionText:
            'Daily milk yield of crossbred cattle in winter(liter/day)',
        questionType: QuestionType.vulnerability,
        category: 'Agriculture & Dairying',
      ),
      QuestionModel(
        variableNumber: '27',
        questionText: 'Amount of milk sold daily (in litre)',
        questionType: QuestionType.vulnerability,
        category: 'Agriculture & Dairying',
      ),
      QuestionModel(
        variableNumber: '28',
        questionText: 'Daily milk consumption of the household (in litre)',
        questionType: QuestionType.vulnerability,
        category: 'Agriculture & Dairying',
      ),
      QuestionModel(
        variableNumber: '29',
        questionText: 'Number of sources of income',
        questionType: QuestionType.vulnerability,
        category: 'Livelihood & Income',
      ),
      QuestionModel(
        variableNumber: '30',
        questionText:
            'Total annual income from all sources(approximately in Rs.)',
        questionType: QuestionType.vulnerability,
        category: 'Livelihood & Income',
      ),
      QuestionModel(
        variableNumber: '31',
        questionText: 'Income from agriculture (in %)',
        questionType: QuestionType.vulnerability,
        category: 'Livelihood & Income',
      ),
      QuestionModel(
        variableNumber: '32',
        questionText: 'Income from dairying (in %)',
        questionType: QuestionType.vulnerability,
        category: 'Livelihood & Income',
      ),
      QuestionModel(
        variableNumber: '33',
        questionText: 'Income from other sources (in %)',
        questionType: QuestionType.vulnerability,
        category: 'Livelihood & Income',
      ),
      QuestionModel(
        variableNumber: '34',
        questionText:
            '34. Presence of water or land-related conflicts (Yes=1/ No=0)',
        questionType: QuestionType.vulnerability,
        category: 'Social Capital',
      ),
      QuestionModel(
        variableNumber: '35',
        questionText:
            '35. Number of years of membership in SHG/FIGs/ FPOs/ CIGs',
        questionType: QuestionType.vulnerability,
        category: 'Social Capital',
      ),
      QuestionModel(
        variableNumber: '29',
        questionText: 'Number of sources of income',
        questionType: QuestionType.vulnerability,
        category: 'Social Capital',
      ),
      QuestionModel(
        variableNumber: '37',
        questionText: '37. Number of visits by extension agents in a year',
        questionType: QuestionType.vulnerability,
        category: 'Social Capital',
      ),
      QuestionModel(
        variableNumber: '38',
        questionText:
            '38. Number of visits by government or private veterinarians in a year',
        questionType: QuestionType.vulnerability,
        category: 'Social Capital',
      ),

      QuestionModel(
        variableNumber: '21',
        questionText: 'Types of diseases',
        questionType: QuestionType.exposure,
        category: 'Agriculture & Dairying',
      ),
      QuestionModel(
        variableNumber: '22',
        questionText: 'Daily milk yield of buffalo in summer (in litres/day)',
        questionType: QuestionType.exposure,
        category: 'Agriculture & Dairying',
      ),
      QuestionModel(
        variableNumber: '23',
        questionText:
            'Daily milk yield of indigenous cattle in summer (in litres/day)',
        questionType: QuestionType.exposure,
        category: 'Agriculture & Dairying',
      ),
      QuestionModel(
        variableNumber: '24',
        questionText:
            'Daily milk yield of crossbred cattle in summer (in litres/day)',
        questionType: QuestionType.exposure,
        category: 'Agriculture & Dairying',
      ),
      QuestionModel(
        variableNumber: '25',
        questionText: 'Daily milk yield of buffalo in winter (in litres/day)',
        questionType: QuestionType.exposure,
        category: 'Agriculture & Dairying',
      ),
      QuestionModel(
        variableNumber: '26',
        questionText:
            'Daily milk yield of indigenous cattle in winter (in litres/day)',
        questionType: QuestionType.exposure,
        category: 'Agriculture & Dairying',
      ),
      QuestionModel(
        variableNumber: '27',
        questionText:
            'Daily milk yield of crossbred cattle in winter (in litres/day)',
        questionType: QuestionType.exposure,
        category: 'Agriculture & Dairying',
      ),
      QuestionModel(
        variableNumber: '39',
        questionText: 'Distance to nearest human health care service (in km)',
        questionType: QuestionType.vulnerability,
        category: 'Agriculture & Dairying',
      ),
      QuestionModel(
        variableNumber: '40',
        questionText:
            'Distance to nearest veterinary health care service(in km)',
        questionType: QuestionType.vulnerability,
        category: 'Agriculture & Dairying',
      ),
      QuestionModel(
        variableNumber: '41',
        questionText: 'Distance to nearest all weather road (in km)',
        questionType: QuestionType.vulnerability,
        category: 'Livelihood & Income',
      ),
      QuestionModel(
        variableNumber: '42',
        questionText: 'Distance to nearest market (in km)',
        questionType: QuestionType.vulnerability,
        category: 'Livelihood & Income',
      ),
      QuestionModel(
        variableNumber: '43',
        questionText:
            'Distance to nearest artificial insemination centre (in km)',
        questionType: QuestionType.vulnerability,
        category: 'Livelihood & Income',
      ),
      QuestionModel(
        variableNumber: '44',
        questionText: 'Distance to nearest milk collection centre (in km)',
        questionType: QuestionType.vulnerability,
        category: 'Social Capital',
      ),
      QuestionModel(
        variableNumber: '45',
        questionText: 'Number of visits by extension agents in a year',
        questionType: QuestionType.vulnerability,
        category: 'Social Capital',
      ),


      QuestionModel(
        variableNumber: '44.1',
        questionText: '1. Increasing temperature during summers',
        questionType: QuestionType.vulnerability,
        category: 'Climate - Perception',
      ),
      QuestionModel(
        variableNumber: '44.2',
        questionText: '2. Decreasing temperature during winters',
        questionType: QuestionType.vulnerability,
        category: 'Climate - Perception',
      ),
      QuestionModel(
        variableNumber: '44.3',
        questionText: '3. Prolonged summer',
        questionType: QuestionType.vulnerability,
        category: 'Climate - Perception',
      ),
      QuestionModel(
        variableNumber: '44.4',
        questionText: '4. Reduced span of winters',
        questionType: QuestionType.vulnerability,
        category: 'Climate - Perception',
      ),
      QuestionModel(
        variableNumber: '44.5',
        questionText: '4.Delay onset of monsoon',
        questionType: QuestionType.vulnerability,
        category: 'Climate - Perception',
      ),
      QuestionModel(
        variableNumber: '44.6',
        questionText: '6.Occurrence of heavy fog during winter season',
        questionType: QuestionType.vulnerability,
        category: 'Climate - Perception',
      ),
      QuestionModel(
        variableNumber: '44.7',
        questionText: '7. Unpredictable rainfalls',
        questionType: QuestionType.vulnerability,
        category: 'Climate - Perception',
      ),
      QuestionModel(
        variableNumber: '44.8',
        questionText: '8. Decline in precipitation',
        questionType: QuestionType.vulnerability,
        category: 'Climate - Perception',
      ),
      QuestionModel(
        variableNumber: '44.9',
        questionText: '9. Long dry spells and increased rate of drought',
        questionType: QuestionType.vulnerability,
        category: 'Climate - Perception',
      ),
      QuestionModel(
        variableNumber: '44.10',
        questionText: '10. Change in the season cycle during last 10-15 years',
        questionType: QuestionType.vulnerability,
        category: 'Climate - Perception',
      ),
      QuestionModel(
        variableNumber: '44.11',
        questionText: '11. Increased rate of heat waves',
        questionType: QuestionType.vulnerability,
        category: 'Climate - Perception',
      ),
      QuestionModel(
        variableNumber: '44.12',
        questionText: '12. Increased rate of cold waves',
        questionType: QuestionType.vulnerability,
        category: 'Climate - Perception',
      ),
      QuestionModel(
        variableNumber: '44.13',
        questionText: '13. Increased high intensity rainfall events',
        questionType: QuestionType.vulnerability,
        category: 'Climate - Perception',
      ),
      QuestionModel(
        variableNumber: '44.14',
        questionText: '14. Increased THI',
        questionType: QuestionType.vulnerability,
        category: 'Climate - Perception',
      ),
      QuestionModel(
        variableNumber: '44.15',
        questionText: '15. Increased events of hailstorm',
        questionType: QuestionType.vulnerability,
        category: 'Climate - Perception',
      ),
      QuestionModel(
        variableNumber: '44.16',
        questionText: '16. Increase in relative humidity',
        questionType: QuestionType.vulnerability,
        category: 'Climate - Perception',
      ),
      QuestionModel(
        variableNumber: '45.1',
        questionText:
            '1. Agriculture and dairy farming are extremely vulnerable to Climate Change',
        questionType: QuestionType.vulnerability,
        category: 'Climate - Awareness',
      ),
      QuestionModel(
        variableNumber: '45.2',
        questionText: '2. Heat stress may reduce the fertility of livestock',
        questionType: QuestionType.vulnerability,
        category: 'Climate - Awareness',
      ),
      QuestionModel(
        variableNumber: '45.3',
        questionText:
            '3. Increase in temperature and humidity is the cause behind declined milk production of dairy bovine',
        questionType: QuestionType.vulnerability,
        category: 'Climate - Awareness',
      ),
      QuestionModel(
        variableNumber: '45.4',
        questionText:
            '4. Heat stress may cause the reduced feed intake of the livestock',
        questionType: QuestionType.vulnerability,
        category: 'Climate - Awareness',
      ),
      QuestionModel(
        variableNumber: '45.5',
        questionText:
            '5. Climate Change is the cause of increased rate of temperature-related illness and vector borne diseases among livestock',
        questionType: QuestionType.vulnerability,
        category: 'Climate - Awareness',
      ),
      QuestionModel(
        variableNumber: '45.6',
        questionText:
            '6. The type, frequency and intensity of extreme climatic events are expected to rise even with a slight change in the climate',
        questionType: QuestionType.vulnerability,
        category: 'Climate - Awareness',
      ),
      QuestionModel(
        variableNumber: '45.7',
        questionText:
            '7. Changes in rainfall pattern are likely to lead to severe water shortage and/or flooding',
        questionType: QuestionType.vulnerability,
        category: 'Climate - Awareness',
      ),
      QuestionModel(
        variableNumber: '46.1',
        questionText: '1. Rearing resilience breeds of livestock',
        questionType: QuestionType.vulnerability,
        category: 'Climate - Preparedness',
      ),
      QuestionModel(
        variableNumber: '46.2',
        questionText: '2. Use of rubber mats',
        questionType: QuestionType.vulnerability,
        category: 'Climate - Preparedness',
      ),
      QuestionModel(
        variableNumber: '46.3',
        questionText: '3. Cropping climate resilience fodder variety',
        questionType: QuestionType.vulnerability,
        category: 'Climate - Preparedness',
      ),
      QuestionModel(
        variableNumber: '46.4',
        questionText: '4. Use of fans',
        questionType: QuestionType.vulnerability,
        category: 'Climate - Preparedness',
      ),
      QuestionModel(
        variableNumber: '46.5',
        questionText:
            '5. Cultivation of climate resilient crop varieties (including fodder)',
        questionType: QuestionType.vulnerability,
        category: 'Climate - Preparedness',
      ),
      QuestionModel(
        variableNumber: '46.6',
        questionText: '6. Using of animal shade for heat stress management',
        questionType: QuestionType.vulnerability,
        category: 'Climate - Preparedness',
      ),
      QuestionModel(
        variableNumber: '46.7',
        questionText:
            '7. Herd diversification (whether own different kinds of animals: cattle, buffaloes, goats, pigs, sheeps)',
        questionType: QuestionType.vulnerability,
        category: 'Climate - Preparedness',
      ),
      QuestionModel(
        variableNumber: '46.8',
        questionText: '8. Availability of adequate drinking water',
        questionType: QuestionType.vulnerability,
        category: 'Climate - Preparedness',
      ),
      QuestionModel(
        variableNumber: '46.9',
        questionText: '9. Deworming of livestock',
        questionType: QuestionType.vulnerability,
        category: 'Climate - Preparedness',
      ),
      QuestionModel(
        variableNumber: '46.10',
        questionText: '10. Follow vaccination schedule',
        questionType: QuestionType.vulnerability,
        category: 'Climate - Preparedness',
      ),
      QuestionModel(
        variableNumber: '46.11',
        questionText: '11. Adoption of integrated farming system',
        questionType: QuestionType.vulnerability,
        category: 'Climate - Preparedness',
      ),
      QuestionModel(
        variableNumber: '46.12',
        questionText: '12. Use of climatic agro-advisory services',
        questionType: QuestionType.vulnerability,
        category: 'Climate - Preparedness',
      ),
      QuestionModel(
        variableNumber: '46.13',
        questionText: '13. Use of early warning dissemination systems',
        questionType: QuestionType.vulnerability,
        category: 'Climate - Preparedness',
      ),
      QuestionModel(
        variableNumber: '46.14',
        questionText: '14. Feeding Jaggery',
        questionType: QuestionType.vulnerability,
        category: 'Climate - Preparedness',
      ),
      QuestionModel(
        variableNumber: '46.15',
        questionText: '15. Massage with mustard oil',
        questionType: QuestionType.vulnerability,
        category: 'Climate - Preparedness',
      ),
      QuestionModel(
        variableNumber: '46.16',
        questionText: '16. Livestock insurance',
        questionType: QuestionType.vulnerability,
        category: 'Climate - Preparedness',
      ),
    ];
  }
}
