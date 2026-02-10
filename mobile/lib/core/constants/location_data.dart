/// Location data for Vietnam cities and districts
class LocationData {
  LocationData._();

  /// List of major cities in Vietnam
  static const List<Map<String, dynamic>> cities = [
    {
      'id': 'hcm',
      'name': 'TP. Hồ Chí Minh',
      'code': 'HCM',
    },
    {
      'id': 'hn',
      'name': 'Hà Nội',
      'code': 'HN',
    },
    {
      'id': 'dn',
      'name': 'Đà Nẵng',
      'code': 'DN',
    },
    {
      'id': 'hp',
      'name': 'Hải Phòng',
      'code': 'HP',
    },
    {
      'id': 'ct',
      'name': 'Cần Thơ',
      'code': 'CT',
    },
    {
      'id': 'bd',
      'name': 'Bình Dương',
      'code': 'BD',
    },
    {
      'id': 'dna',
      'name': 'Đồng Nai',
      'code': 'DNA',
    },
    {
      'id': 'kh',
      'name': 'Khánh Hòa',
      'code': 'KH',
    },
  ];

  /// Districts by city ID
  static const Map<String, List<Map<String, dynamic>>> districtsByCity = {
    'hcm': [
      {'id': 'q1', 'name': 'Quận 1', 'cityId': 'hcm'},
      {'id': 'q2', 'name': 'Quận 2 (TP. Thủ Đức)', 'cityId': 'hcm'},
      {'id': 'q3', 'name': 'Quận 3', 'cityId': 'hcm'},
      {'id': 'q4', 'name': 'Quận 4', 'cityId': 'hcm'},
      {'id': 'q5', 'name': 'Quận 5', 'cityId': 'hcm'},
      {'id': 'q6', 'name': 'Quận 6', 'cityId': 'hcm'},
      {'id': 'q7', 'name': 'Quận 7', 'cityId': 'hcm'},
      {'id': 'q8', 'name': 'Quận 8', 'cityId': 'hcm'},
      {'id': 'q9', 'name': 'Quận 9 (TP. Thủ Đức)', 'cityId': 'hcm'},
      {'id': 'q10', 'name': 'Quận 10', 'cityId': 'hcm'},
      {'id': 'q11', 'name': 'Quận 11', 'cityId': 'hcm'},
      {'id': 'q12', 'name': 'Quận 12', 'cityId': 'hcm'},
      {'id': 'qbt', 'name': 'Quận Bình Thạnh', 'cityId': 'hcm'},
      {'id': 'qgv', 'name': 'Quận Gò Vấp', 'cityId': 'hcm'},
      {'id': 'qpn', 'name': 'Quận Phú Nhuận', 'cityId': 'hcm'},
      {'id': 'qtb', 'name': 'Quận Tân Bình', 'cityId': 'hcm'},
      {'id': 'qtp', 'name': 'Quận Tân Phú', 'cityId': 'hcm'},
      {'id': 'qbc', 'name': 'Quận Bình Tân', 'cityId': 'hcm'},
      {'id': 'qtd', 'name': 'TP. Thủ Đức', 'cityId': 'hcm'},
      {'id': 'hcc', 'name': 'Huyện Củ Chi', 'cityId': 'hcm'},
      {'id': 'hbc', 'name': 'Huyện Bình Chánh', 'cityId': 'hcm'},
      {'id': 'hhm', 'name': 'Huyện Hóc Môn', 'cityId': 'hcm'},
      {'id': 'hnb', 'name': 'Huyện Nhà Bè', 'cityId': 'hcm'},
      {'id': 'hcg', 'name': 'Huyện Cần Giờ', 'cityId': 'hcm'},
    ],
    'hn': [
      {'id': 'hk', 'name': 'Quận Hoàn Kiếm', 'cityId': 'hn'},
      {'id': 'dd', 'name': 'Quận Đống Đa', 'cityId': 'hn'},
      {'id': 'bt', 'name': 'Quận Ba Đình', 'cityId': 'hn'},
      {'id': 'hbt', 'name': 'Quận Hai Bà Trưng', 'cityId': 'hn'},
      {'id': 'hm', 'name': 'Quận Hoàng Mai', 'cityId': 'hn'},
      {'id': 'tx', 'name': 'Quận Thanh Xuân', 'cityId': 'hn'},
      {'id': 'lb', 'name': 'Quận Long Biên', 'cityId': 'hn'},
      {'id': 'cg', 'name': 'Quận Cầu Giấy', 'cityId': 'hn'},
      {'id': 'ty', 'name': 'Quận Tây Hồ', 'cityId': 'hn'},
      {'id': 'bx', 'name': 'Quận Bắc Từ Liêm', 'cityId': 'hn'},
      {'id': 'ntl', 'name': 'Quận Nam Từ Liêm', 'cityId': 'hn'},
      {'id': 'hd', 'name': 'Quận Hà Đông', 'cityId': 'hn'},
      {'id': 'gialm', 'name': 'Huyện Gia Lâm', 'cityId': 'hn'},
      {'id': 'dl', 'name': 'Huyện Đông Anh', 'cityId': 'hn'},
      {'id': 'sl', 'name': 'Huyện Sóc Sơn', 'cityId': 'hn'},
      {'id': 'tc', 'name': 'Huyện Thanh Trì', 'cityId': 'hn'},
    ],
    'dn': [
      {'id': 'hc', 'name': 'Quận Hải Châu', 'cityId': 'dn'},
      {'id': 'tc', 'name': 'Quận Thanh Khê', 'cityId': 'dn'},
      {'id': 'sth', 'name': 'Quận Sơn Trà', 'cityId': 'dn'},
      {'id': 'nhs', 'name': 'Quận Ngũ Hành Sơn', 'cityId': 'dn'},
      {'id': 'lc', 'name': 'Quận Liên Chiểu', 'cityId': 'dn'},
      {'id': 'cx', 'name': 'Quận Cẩm Lệ', 'cityId': 'dn'},
      {'id': 'hvang', 'name': 'Huyện Hòa Vang', 'cityId': 'dn'},
      {'id': 'hsontra', 'name': 'Huyện Hoàng Sa', 'cityId': 'dn'},
    ],
    'hp': [
      {'id': 'hb', 'name': 'Quận Hồng Bàng', 'cityId': 'hp'},
      {'id': 'lc', 'name': 'Quận Lê Chân', 'cityId': 'hp'},
      {'id': 'ng', 'name': 'Quận Ngô Quyền', 'cityId': 'hp'},
      {'id': 'kn', 'name': 'Quận Kiến An', 'cityId': 'hp'},
      {'id': 'haa', 'name': 'Quận Hải An', 'cityId': 'hp'},
      {'id': 'dc', 'name': 'Quận Đồ Sơn', 'cityId': 'hp'},
      {'id': 'dp', 'name': 'Quận Dương Kinh', 'cityId': 'hp'},
    ],
    'ct': [
      {'id': 'nk', 'name': 'Quận Ninh Kiều', 'cityId': 'ct'},
      {'id': 'br', 'name': 'Quận Bình Thủy', 'cityId': 'ct'},
      {'id': 'cr', 'name': 'Quận Cái Răng', 'cityId': 'ct'},
      {'id': 'ol', 'name': 'Quận Ô Môn', 'cityId': 'ct'},
      {'id': 'tt', 'name': 'Quận Thốt Nốt', 'cityId': 'ct'},
    ],
    'bd': [
      {'id': 'tda', 'name': 'TP. Thủ Dầu Một', 'cityId': 'bd'},
      {'id': 'tan', 'name': 'TP. Thuận An', 'cityId': 'bd'},
      {'id': 'di', 'name': 'TP. Dĩ An', 'cityId': 'bd'},
      {'id': 'ba', 'name': 'TP. Bến Cát', 'cityId': 'bd'},
      {'id': 'tu', 'name': 'TP. Tân Uyên', 'cityId': 'bd'},
    ],
    'dna': [
      {'id': 'bh', 'name': 'TP. Biên Hòa', 'cityId': 'dna'},
      {'id': 'lr', 'name': 'TP. Long Khánh', 'cityId': 'dna'},
      {'id': 'nt', 'name': 'Huyện Nhơn Trạch', 'cityId': 'dna'},
      {'id': 'lt', 'name': 'Huyện Long Thành', 'cityId': 'dna'},
      {'id': 'tp', 'name': 'Huyện Trảng Bom', 'cityId': 'dna'},
    ],
    'kh': [
      {'id': 'nt', 'name': 'TP. Nha Trang', 'cityId': 'kh'},
      {'id': 'cr', 'name': 'TP. Cam Ranh', 'cityId': 'kh'},
      {'id': 'nl', 'name': 'Thị xã Ninh Hòa', 'cityId': 'kh'},
      {'id': 'dc', 'name': 'Huyện Diên Khánh', 'cityId': 'kh'},
    ],
  };

  /// Get districts for a specific city
  static List<Map<String, dynamic>> getDistricts(String cityId) {
    return districtsByCity[cityId] ?? [];
  }

  /// Get city by ID
  static Map<String, dynamic>? getCity(String cityId) {
    try {
      return cities.firstWhere((c) => c['id'] == cityId);
    } catch (e) {
      return null;
    }
  }

  /// Get district by ID
  static Map<String, dynamic>? getDistrict(String districtId) {
    for (final districts in districtsByCity.values) {
      try {
        return districts.firstWhere((d) => d['id'] == districtId);
      } catch (e) {
        continue;
      }
    }
    return null;
  }

  /// Get full location string (District, City)
  static String getFullLocationString(String? cityId, String? districtId) {
    final parts = <String>[];
    
    if (districtId != null) {
      final district = getDistrict(districtId);
      if (district != null) {
        parts.add(district['name']);
      }
    }
    
    if (cityId != null) {
      final city = getCity(cityId);
      if (city != null) {
        parts.add(city['name']);
      }
    }
    
    return parts.join(', ');
  }
}
