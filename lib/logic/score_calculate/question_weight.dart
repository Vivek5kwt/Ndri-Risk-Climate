final Map<String, Map<String, dynamic>> questionParams  = {
  '2': {
    'min': 20,
    'max': 88,
    'weight': 2.26602031,
    'isPositive': false,
  },
  '3': {
    'min': 0,
    'max': 6,
    'weight': 0.2,
    'isPositive': true,
  },
  '4': {
    'min': 0,
    'max': 10,
    'weight': 0.12,
    'isPositive': false,
  },
  '5': {
    'min': 0,
    'max': 10,
    'weight': 0.08,
    'isPositive': false,
  },
  '6': {
    'min': 0,
    'max': 12,
    'weight': 2.652984683,
    'isPositive': true,
  },
  '7': {
    'min': 0,
    'max': 9,
    'weight': 1.998600392,
    'isPositive': true,
  },
  '8': {
    'min': 0,
    'max': 4,
    'weight': 2.040972142,
    'isPositive': false,
  },
  '9': {
    'min': 0,
    'max': 3,
    'weight': 1.970125947,
    'isPositive': true,
  },
  '10': {
    'min': 0,
    'max': 2,
    'weight': 0.08,
    'isPositive': false,
  },
  // Vulnerability indicators
  '13': {
    'min': 0,
    'max': 67,
    'weight': 7.8191,
    'isPositive': false,
  },
  '15': {
    'min': 0,
    'max': 67,
    'weight': 7.8191,
    'isPositive': false,
  },
  '18': {
    'min': 0.4,
    'max': 10.97,
    'weight': 3.2558,
    'isPositive': false,
  },
  '18.1': {
    'min': 0,
    'max': 4,
    'weight': 3.6934,
    'isPositive': false,
  },
  '18.8': {
    'min': 0,
    'max': 5,
    'weight': 3.0159,
    'isPositive': false,
  },
  '18.14': {
    'min': 0,
    'max': 5,
    'weight': 4.1064,
    'isPositive': false,
  },
  '28': {
    'min': 0,
    'max': 36,
    'weight': 5.7398,
    'isPositive': false,
  },
  '26': {
    'min': 0,
    'max': 140,
    'weight': 4.4832,
    'isPositive': false,
  },
  // Exposure indicators
  '7_exp': {
    'min': 0,
    'max': 9,
    'weight': 1.9986,
    'isPositive': true,
  },
  '8_exp': {
    'min': 0,
    'max': 4,
    'weight': 2.0410,
    'isPositive': true,
  },
  '6_exp': {
    'min': 0,
    'max': 12,
    'weight': 2.6530,
    'isPositive': true,
  },
  '4_exp': {
    'min': 1,
    'max': 22,
    'weight': 2.6444,
    'isPositive': true,
  },
  '9_exp': {
    'min': 0,
    'max': 3,
    'weight': 1.9701,
    'isPositive': true,
  },
  '19_exp': {
    'min': 0,
    'max': 10,
    'weight': 1.5923,
    'isPositive': true,
  },
  '34_exp': {
    'min': 0,
    'max': 1,
    'weight': 1.5923,
    'isPositive': true,
  },
  '20_exp': {
    'min': 0,
    'max': 5,
    'weight': 1.3525,
    'isPositive': true,
  },
  '29_exp': {
    'min': 1,
    'max': 5,
    'weight': 2.2488,
    'isPositive': false,
  },
  '10_exp': {
    'min': 1,
    'max': 3,
    'weight': 3.8990,
    'isPositive': false,
  },
  '23_exp': {
    'min': 0,
    'max': 20,
    'weight': 3.0730,
    'isPositive': false,
  },
  '24_exp': {
    'min': 0.5,
    'max': 20,
    'weight': 3.2619,
    'isPositive': false,
  },
  '25_exp': {
    'min': 0,
    'max': 30,
    'weight': 4.7147,
    'isPositive': false,
  },
  '26_exp': {
    'min': 0.5,
    'max': 40,
    'weight': 4.5380,
    'isPositive': false,
  },
  '21_exp': {
    'min': 0.5,
    'max': 25,
    'weight': 4.3995,
    'isPositive': false,
  },
  '22_exp': {
    'min': 0.5,
    'max': 26,
    'weight': 4.6060,
    'isPositive': false,
  },
};

int mapEducation(String val) {
  const list = [
    'No formal schooling',
    'Primary',
    'Secondary',
    'Higher secondary',
    'Diploma/certificate course',
    'Graduate',
    'Post graduate and above',
  ];
  return list.indexOf(val);
}

int mapHouseType(String val) {
  if (val == 'Permanent Pucca house') return 0;
  if (val == 'Permanent Kaccha house') return 1;
  return 2;
}

// Keys for vulnerability and exposure questions used in score calculation
final Set<String> vulnerabilityKeys = {
  '13', '15', '18', '18.1', '18.8', '18.14', '28', '26'
};

final Set<String> exposureKeys = {
  '7_exp', '8_exp', '6_exp', '4_exp', '9_exp',
  '19_exp', '34_exp', '20_exp', '29_exp', '10_exp',
  '23_exp', '24_exp', '25_exp', '26_exp', '21_exp', '22_exp'
};

double _parseAnswer(String key, Map<String, String> ans) {
  String? raw = ans[key];
  if (raw == null || raw.isEmpty) return 0.0;
  return double.tryParse(raw) ?? 0.0;
}

double _calcFor(String key, Map<String, String> ans) {
  if (!questionParams.containsKey(key)) return 0.0;
  final p = questionParams[key]!;
  double input = _parseAnswer(key, ans);
  // Special cases for derived inputs
  if (key == '13') {
    input = _parseAnswer('13', ans);
    if (input == 0.0) {
      input = _parseAnswer('13.1', ans) + _parseAnswer('13.2', ans) - _parseAnswer('13.3', ans);
    }
  } else if (key == '18') {
    input = _parseAnswer('18', ans);
    if (input == 0.0) {
      double sum = 0.0;
      for (var i = 1; i <= 18; i++) {
        sum += _parseAnswer('18.$i', ans);
      }
      input = sum;
    }
  }
  final min = p['min'] as num;
  final max = p['max'] as num;
  final weight = p['weight'] as double;
  final isPositive = p['isPositive'] as bool;
  double norm = max == min ? 0.0 : ((input - min) / (max - min));
  double value = (isPositive ? norm : (1 - norm)) * weight;
  return value.clamp(0.0, weight);
}

double computeScore(Map<String, String> ans, Set<String> keys) {
  double sum = 0.0;
  double wSum = 0.0;
  for (final k in keys) {
    if (!questionParams.containsKey(k)) continue;
    final weight = questionParams[k]!['weight'] as double;
    wSum += weight;
    sum += _calcFor(k, ans);
  }
  if (wSum == 0) return 0.0;
  return sum / wSum;
}

double computeVulnerabilityScore(Map<String, String> ans) =>
    computeScore(ans, vulnerabilityKeys);

double computeExposureScore(Map<String, String> ans) =>
    computeScore(ans, exposureKeys);

