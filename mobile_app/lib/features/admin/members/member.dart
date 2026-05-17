// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'member.freezed.dart';
part 'member.g.dart';

// ── Blood group options ───────────────────────────────────────────────────────
const kBloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

// ── Religion options ──────────────────────────────────────────────────────────
const kReligions = ['Islam', 'Hinduism', 'Christianity', 'Buddhism', 'Others'];
const kGenders = ['Male', 'Female', 'Other'];

// ── Hobby options ─────────────────────────────────────────────────────────────
const kHobbies = [
  'Reading',
  'Sports',
  'Music',
  'Cooking',
  'Travel',
  'Gardening',
  'Gaming',
  'Photography',
  'Fitness',
  'Art',
  'Others',
];

// ── Member ────────────────────────────────────────────────────────────────────

/// Domain model for a gym member.
///
/// Written as a plain class (no build_runner required) so new fields can be
/// added without regenerating code. The freezed part files are kept as empty
/// stubs to satisfy the `part` declarations.
class Member {
  const Member({
    required this.id,
    required this.name,
    required this.phone,
    this.status = 'active',
    this.joinDate,
    this.currentWeight,
    this.heightCm,
    this.dateOfBirth,
    this.religion,
    this.bloodGroup,
    this.hobbies = const [],
    this.presentAddress,
    this.permanentAddress,
    this.occupation,
    this.nid,
    this.emergencyPhone,
    this.goal,
    this.mustChangePassword = false,
    this.activeSubscription,
    this.imageUrl,
    required this.gender,
  });

  final String id;
  final String name;
  final String phone;
  final String status;
  final DateTime? joinDate;
  final double? currentWeight;
  final double? heightCm;
  final DateTime? dateOfBirth;
  final String? religion;
  final String? bloodGroup;
  final List<String> hobbies;
  final String? presentAddress;
  final String? permanentAddress;
  final String? occupation;
  final String? nid;
  final String? emergencyPhone;
  final String? goal;
  final bool mustChangePassword;
  final MemberSubscription? activeSubscription;
  final String? imageUrl;
  final String gender;

  // ── Computed ────────────────────────────────────────────────────────────────

  /// Body Mass Index — null when weight or height is unknown.
  double? get bmi {
    if (currentWeight == null || heightCm == null || heightCm! <= 0) return null;
    final h = heightCm! / 100.0;
    return currentWeight! / (h * h);
  }

  /// BMI category string.
  String? get bmiCategory {
    final b = bmi;
    if (b == null) return null;
    if (b < 18.5) return 'Underweight';
    if (b < 25.0) return 'Normal';
    if (b < 30.0) return 'Overweight';
    return 'Obese';
  }

  /// Age in years — null when date of birth is unknown.
  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  /// Height in ft-in format (e.g. 5' 7").
  String get heightDisplay {
    if (heightCm == null || heightCm! <= 0) return '—';
    final totalInches = heightCm! / 2.54;
    final feet = (totalInches / 12).floor();
    final inches = (totalInches % 12).round();
    return "$feet' $inches\"";
  }

  /// Ideal weight range (BMI 18.5 - 25.0).
  String get idealWeightRange {
    if (heightCm == null || heightCm! <= 0) return '—';
    final h = heightCm! / 100.0;
    final min = 18.5 * (h * h);
    final max = 24.9 * (h * h);
    return '${min.toStringAsFixed(1)} - ${max.toStringAsFixed(1)} kg';
  }

  /// BMI Health Tip based on category.
  String get bmiTip {
    final cat = bmiCategory;
    if (cat == 'Underweight') {
      return 'Focus on nutrient-dense foods and strength training to build muscle.';
    }
    if (cat == 'Normal') {
      return 'Great job! Maintain your healthy lifestyle with balanced nutrition.';
    }
    if (cat == 'Overweight') {
      return 'Focus on a gradual calorie deficit and regular cardio to reach your goal.';
    }
    if (cat == 'Obese') {
      return 'Consult with a trainer for a structured weight loss and cardio plan.';
    }
    return 'Track your weight and height to get personalized health tips.';
  }

  // ── Serialisation ───────────────────────────────────────────────────────────

  factory Member.fromJson(Map<String, dynamic> json) => Member(
        id: json['id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String,
        status: json['status'] as String? ?? 'active',
        joinDate: json['join_date'] == null
            ? null
            : DateTime.parse(json['join_date'] as String),
        currentWeight: (json['current_weight'] as num?)?.toDouble(),
        heightCm: (json['height_cm'] as num?)?.toDouble(),
        dateOfBirth: json['date_of_birth'] == null
            ? null
            : DateTime.parse(json['date_of_birth'] as String),
        religion: json['religion'] as String?,
        bloodGroup: json['blood_group'] as String?,
        hobbies: (json['hobbies'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        presentAddress: json['present_address'] as String?,
        permanentAddress: json['permanent_address'] as String?,
        occupation: json['occupation'] as String?,
        nid: json['nid'] as String?,
        emergencyPhone: json['emergency_phone'] as String?,
        goal: json['goal'] as String?,
        mustChangePassword: json['must_change_password'] as bool? ?? false,
        activeSubscription: json['active_subscription'] == null
            ? null
            : MemberSubscription.fromJson(
                json['active_subscription'] as Map<String, dynamic>,
              ),
        imageUrl: json['imageUrl'] as String?,
        gender: (json['gender'] != null && 
                (json['gender'] as String).isNotEmpty && 
                kGenders.contains(json['gender']))
            ? json['gender'] as String
            : 'Other',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'status': status,
        'join_date': joinDate?.toIso8601String().split('T')[0],
        'current_weight': currentWeight,
        'height_cm': heightCm,
        'date_of_birth': dateOfBirth?.toIso8601String().split('T')[0],
        'religion': religion,
        'blood_group': bloodGroup,
        'hobbies': hobbies,
        'present_address': presentAddress,
        'permanent_address': permanentAddress,
        'occupation': occupation,
        'nid': nid,
        'emergency_phone': emergencyPhone,
        'goal': goal,
        'must_change_password': mustChangePassword,
        'active_subscription': activeSubscription?.toJson(),
        'imageUrl': imageUrl,
        'gender': gender,
      };

  // ── copyWith (sentinel pattern for nullable fields) ─────────────────────────

  Member copyWith({
    String? id,
    String? name,
    String? phone,
    String? status,
    Object? joinDate = _absent,
    Object? currentWeight = _absent,
    Object? heightCm = _absent,
    Object? dateOfBirth = _absent,
    Object? religion = _absent,
    Object? bloodGroup = _absent,
    List<String>? hobbies,
    Object? presentAddress = _absent,
    Object? permanentAddress = _absent,
    Object? occupation = _absent,
    Object? nid = _absent,
    Object? emergencyPhone = _absent,
    Object? goal = _absent,
    bool? mustChangePassword,
    Object? activeSubscription = _absent,
    Object? imageUrl = _absent,
    String? gender,
  }) =>
      Member(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        status: status ?? this.status,
        joinDate: joinDate == _absent ? this.joinDate : joinDate as DateTime?,
        currentWeight: currentWeight == _absent
            ? this.currentWeight
            : currentWeight as double?,
        heightCm:
            heightCm == _absent ? this.heightCm : heightCm as double?,
        dateOfBirth: dateOfBirth == _absent
            ? this.dateOfBirth
            : dateOfBirth as DateTime?,
        religion:
            religion == _absent ? this.religion : religion as String?,
        bloodGroup: bloodGroup == _absent
            ? this.bloodGroup
            : bloodGroup as String?,
        hobbies: hobbies ?? this.hobbies,
        presentAddress: presentAddress == _absent
            ? this.presentAddress
            : presentAddress as String?,
        permanentAddress: permanentAddress == _absent
            ? this.permanentAddress
            : permanentAddress as String?,
        occupation: occupation == _absent
            ? this.occupation
            : occupation as String?,
        nid: nid == _absent ? this.nid : nid as String?,
        emergencyPhone: emergencyPhone == _absent
            ? this.emergencyPhone
            : emergencyPhone as String?,
        goal: goal == _absent ? this.goal : goal as String?,
        mustChangePassword: mustChangePassword ?? this.mustChangePassword,
        activeSubscription: activeSubscription == _absent
            ? this.activeSubscription
            : activeSubscription as MemberSubscription?,
        imageUrl:
            imageUrl == _absent ? this.imageUrl : imageUrl as String?,
        gender: gender ?? this.gender,
      );
}

/// Sentinel — distinguishes "not passed" from "explicitly null" in [copyWith].
const _absent = Object();

// ── MemberSubscription ────────────────────────────────────────────────────────

@freezed
class MemberSubscription with _$MemberSubscription {
  const factory MemberSubscription({
    required String id,
    @JsonKey(name: 'plan_template_id') required String planId,
    @JsonKey(name: 'plan_name') @Default('') String planName,
    @JsonKey(name: 'plan_price') @Default(0.0) double planPrice,
    @JsonKey(name: 'start_date') required DateTime startDate,
    @JsonKey(name: 'end_date') required DateTime endDate,
    @JsonKey(name: 'final_price') required double finalPrice,
    @JsonKey(name: 'money_paid') @Default(0.0) double moneyPaid,
    @JsonKey(name: 'money_left') @Default(0.0) double moneyLeft,
    @JsonKey(name: 'billing_type') @Default('prepaid') String billingType,
    @JsonKey(name: 'prepaid_due_date') DateTime? prepaidDueDate,
    @JsonKey(name: 'postpaid_grace_before') @Default(5) int postpaidGraceBefore,
    @JsonKey(name: 'postpaid_grace_after') @Default(5) int postpaidGraceAfter,
    @JsonKey(name: 'billing_status') @Default('') String billingStatus,
    @JsonKey(name: 'payment_window_start') DateTime? paymentWindowStart,
    @JsonKey(name: 'payment_window_end') DateTime? paymentWindowEnd,
    @JsonKey(name: 'days_until_due') int? daysUntilDue,
    String? note,
    @Default('active') String status,
  }) = _MemberSubscription;

  factory MemberSubscription.fromJson(Map<String, dynamic> json) =>
      _$MemberSubscriptionFromJson(json);
}
