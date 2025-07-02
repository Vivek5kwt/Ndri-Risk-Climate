import 'package:dio/dio.dart';

class LocationService {
  LocationService._();

  static final LocationService _i = LocationService._();

  factory LocationService() => _i;

  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://cdn-api.co-vin.in/api/v2',
    headers: const {'User-Agent': 'Mozilla/5.0'},
  ));

  late List<String> _states;
  final Map<String, int> _stateId = {};
  final Map<String, List<String>> _distCache = {};

  final Map<String, double> _hazard = {
    "Ambala": 0.310321663,
    "Bhiwani": 0.488023411,
    "Faridabad": 0.415103176,
    "Fatehabad": 0.585504648,
    "Gurgaon": 0.505139199,
    "Hisar": 0.458768913,
    "Jhajjar": 0.49039127,
    "Jind": 0.503537399,
    "Kaithal": 0.447268293,
    "Karnal": 0.349361741,
    "Kurukshetra": 0.333940038,
    "Mahendragarh": 0.55190417,
    "Mewat": 0.427797051,
    "Palwal": 0.366533575,
    "Panchkula": 0.396218951,
    "Panipat": 0.450673788,
    "Rewari": 0.388318411,
    "Rohtak": 0.441572268,
    "Sirsa": 0.595030967,
    "Sonipat": 0.407133943,
    "Yamunanagar": 0.371252847,
    "Ganganagar": 0.598254242,
    "Hanumangarh": 0.655265435,
    "Agra": 0.577676579,
    "Aligarh": 0.324758197,
    "Allahabad": 0.413622247,
    "Ambedkar Nagar": 0.37096779,
    "Auraiya": 0.563792193,
    "Azamgarh": 0.406492913,
    "Baghpat": 0.347786304,
    "Bahraich": 0.331891325,
    "Ballia": 0.236594273,
    "Balrampur": 0.379637299,
    "Banda": 0.374723204,
    "Bara Banki": 0.33022693,
    "Bareilly": 0.525986871,
    "Basti": 0.424915494,
    "Bijnor": 0.34822749,
    "Budaun": 0.311681713,
    "Bulandshahr": 0.493873702,
    "Chandauli": 0.22490624,
    "Chitrakoot": 0.40045051,
    "Deoria": 0.383092294,
    "Etah": 0.414980844,
    "Etawah": 0.601682843,
    "Faizabad": 0.469085517,
    "Farrukhabad": 0.359923437,
    "Fatehpur": 0.541574893,
    "Firozabad": 0.354795252,
    "Gautam Buddha Nagar": 0.402810196,
    "Ghaziabad": 0.49403293,
    "Ghazipur": 0.392448955,
    "Gonda": 0.330372249,
    "Gorakhpur": 0.362353194,
    "Hamirpur": 0.497155429,
    "Hardoi": 0.356721896,
    "Jalaun": 0.460791399,
    "Jaunpur": 0.321807035,
    "Jhansi": 0.402738719,
    "Jyotiba Phule Nagar": 0.360785821,
    "Kannauj": 0.374674955,
    "Kanpur Nagar": 0.477525238,
    "Kanshiram Nagar": 0.384868259,
    "Kaushambi": 0.355173192,
    "Kheri": 0.384991108,
    "Kushinagar": 0.427137924,
    "Lalitpur": 0.390107062,
    "Lucknow": 0.389778075,
    "Mahamaya Nagar": 0.444251199,
    "Mahoba": 0.344052773,
    "Mahrajganj": 0.346494842,
    "Mainpuri": 0.54372203,
    "Mathura": 0.440713994,
    "Mau": 0.335523054,
    "Meerut": 0.445835898,
    "Mirzapur": 0.331617628,
    "Moradabad": 0.40751509,
    "Muzaffarnagar": 0.339290724,
    "Pilibhit": 0.356037929,
    "Pratapgarh": 0.319821317,
    "Rae Bareli": 0.498821071,
    "Ramabai Nagar": 0.365153733,
    "Rampur": 0.398725784,
    "Saharanpur": 0.325839479,
    "Sant Kabir Nagar": 0.377172807,
    "Sant Ravidas Nagar (Bhadohi)": 0.328075355,
    "Shahjahanpur": 0.33192499,
    "Shrawasti": 0.277204554,
    "Siddharthnagar": 0.398015954,
    "Sitapur": 0.437950785,
    "Sonbhadra": 0.307298226,
    "Sultanpur": 0.256324295,
    "Unnao": 0.491102052,
    "Varanasi": 0.378179441,
    "Araria": 0.282188608,
    "Arwal": 0.34127673,
    "Aurangabad": 0.282244831,
    "Banka": 0.362465561,
    "Begusarai": 0.344541849,
    "Bhagalpur": 0.417653215,
    "Bhojpur": 0.356333455,
    "Buxar": 0.342546433,
    "Darbhanga": 0.470236615,
    "Gaya": 0.291922532,
    "Gopalganj": 0.404565102,
    "Jamui": 0.282069777,
    "Jehanabad": 0.34695531,
    "Kaimur (Bhabua)": 0.274811278,
    "Katihar": 0.379500882,
    "Khagaria": 0.412298431,
    "Kishanganj": 0.227408254,
    "Lakhisarai": 0.33502471,
    "Madhepura": 0.293708495,
    "Madhubani": 0.436951985,
    "Munger": 0.439567072,
    "Muzaffarpur": 0.309182813,
    "Nalanda": 0.423733185,
    "Nawada": 0.39654537,
    "Pashchim Champaran": 0.350062292,
    "Patna": 0.36399003,
    "Purba Champaran": 0.388990796,
    "Purnia": 0.285367204,
    "Rohtas": 0.253742558,
    "Saharsa": 0.375171379,
    "Samastipur": 0.446166216,
    "Saran": 0.367330574,
    "Sheikhpura": 0.421680349,
    "Sheohar": 0.378009093,
    "Sitamarhi": 0.359941493,
    "Siwan": 0.334844538,
    "Supaul": 0.349148413,
    "Vaishali": 0.3544185,
    "Bankura": 0.185906573,
    "Barddhaman": 0.312893307,
    "Birbhum": 0.283570998,
    "Dakshin Dinajpur": 0.399921598,
    "Darjiling": 0.110760892,
    "Haora": 0.345231297,
    "Hugli": 0.354748314,
    "Jalpaiguri": 0.187995574,
    "Koch Bihar": 0.231705573,
    "Kolkata": 0.316183847,
    "Maldah": 0.312324568,
    "Murshidabad": 0.22820244,
    "Nadia": 0.348306002,
    "North Twenty Four Parganas": 0.340786481,
    "Paschim Medinipur": 0.292264915,
    "Purba Medinipur": 0.26868821,
    "Puruliya": 0.157598382,
    "South Twenty Four Parganas": 0.263203143,
    "Uttar Dinajpur": 0.205966705,
    "Hardwar": 0.14232932,
    "Udham Singh Nagar": 0.608926109,
    "Amritsar": 0.38764544,
    "Barnala": 0.551045281,
    "Bathinda": 0.612206748,
    "Faridkot": 0.546289639,
    "Fatehgarh Sahib": 0.478901936,
    "Firozpur": 0.602179589,
    "Gurdaspur": 0.343496502,
    "Hoshiarpur": 0.262401795,
    "Jalandhar": 0.366889982,
    "Kapurthala": 0.366856573,
    "Ludhiana": 0.568622982,
    "Mansa": 0.456725285,
    "Moga": 0.53174428,
    "Mohali": 0.430994827,
    "Muktsar": 0.567253341,
    "Patiala": 0.350358901,
    "Rupnagar": 0.510245247,
    "Sahibzada Ajit Singh Nagar": 0.474449175,
    "Sangrur": 0.305948149,
    "Tarn Taran": 0.383540753,
  };

  double hazardFor(String district) {
    final normalized = district.trim().toLowerCase();
    for (final entry in _hazard.entries) {
      if (entry.key.trim().toLowerCase() == normalized) {
        return entry.value;
      }
    }
    return 0.0;
  }

  List<String> get states => _states;

  int idFor(String state) => _stateId[state] ?? 0;

  List<String>? cachedDistricts(String state) => _distCache[state];

  Future<void> prefetchStates() async {
    final r = await _dio.get('/admin/location/states');
    final raw = (r.data?['states'] as List<dynamic>);
    _states = raw.map((e) => e['state_name'] as String).toList()..sort();
    for (var e in raw) {
      _stateId[e['state_name']] = e['state_id'];
    }
  }

  Future<List<String>> districts(String state) async {
    if (_distCache.containsKey(state)) return _distCache[state]!;
    final r = await _dio.get('/admin/location/districts/${_stateId[state]}');
    final list = (r.data?['districts'] as List<dynamic>)
        .map((e) => e['district_name'] as String)
        .toList()
      ..sort();
    _distCache[state] = list;
    return list;
  }
}
