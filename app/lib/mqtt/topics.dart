/// WBIoT Topic 规范（第 5 课）。集中管理，避免魔法字符串散落各处。
class Topics {
  static String propertyPost(String productKey, String deviceName) =>
      'wbiot/$productKey/$deviceName/property/post';
  static String propertySet(String productKey, String deviceName) =>
      'wbiot/$productKey/$deviceName/property/set';
  static String service(String productKey, String deviceName, String name) =>
      'wbiot/$productKey/$deviceName/service/$name';
  static String serviceReply(
          String productKey, String deviceName, String name) =>
      'wbiot/$productKey/$deviceName/service/$name/reply';
  static String event(String productKey, String deviceName, String name) =>
      'wbiot/$productKey/$deviceName/event/$name';
}
