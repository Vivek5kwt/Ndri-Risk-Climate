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

