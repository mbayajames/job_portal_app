class NotificationSettings {
  bool emailNotifications;
  bool pushNotifications;
  bool smsNotifications;
  bool jobAlerts;
  bool applicationUpdates;

  NotificationSettings({
    this.emailNotifications = true,
    this.pushNotifications = true,
    this.smsNotifications = false,
    this.jobAlerts = true,
    this.applicationUpdates = true,
  });

  /// Convert JSON → NotificationSettings
  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      emailNotifications: json['emailNotifications'] ?? true,
      pushNotifications: json['pushNotifications'] ?? true,
      smsNotifications: json['smsNotifications'] ?? false,
      jobAlerts: json['jobAlerts'] ?? true,
      applicationUpdates: json['applicationUpdates'] ?? true,
    );
  }

  /// Convert NotificationSettings → JSON
  Map<String, dynamic> toJson() {
    return {
      'emailNotifications': emailNotifications,
      'pushNotifications': pushNotifications,
      'smsNotifications': smsNotifications,
      'jobAlerts': jobAlerts,
      'applicationUpdates': applicationUpdates,
    };
  }
}
