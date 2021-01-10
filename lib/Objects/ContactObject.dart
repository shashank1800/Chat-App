class ContactObject {
  String name;
  String phone;
  String profileURL = "";
  String profileID = "";
  bool isRequestPending = false;
  bool isHeFriend = false;
  bool isOnline = false;
  
  // List<String> friends = [];
  // List<String> pendingFriends = [];
  ContactObject(String name, String phone) {
    this.name = name;
    this.phone = phone;
  }

  void setName(String name) {
    this.name = name;
  }

  String getName() {
    return this.name;
  }

  void setPhone(String phoneNumber) {
    this.phone = phoneNumber;
  }

  String getPhone() {
    return this.phone;
  }

  String getProfileURL() {
    return this.profileURL;
  }

  String getProfileID() {
    return this.profileID;
  }

  bool isReqstPending() {
    return this.isRequestPending;
  }

  void setIsHeFriend(bool value) {
    this.isHeFriend = value;
  }

  void setIsRequestPending(bool value) {
    this.isRequestPending = value;
  }

  void setProfileURL(String profileURL) {
    this.profileURL = profileURL;
  }

  void setProfileID(String profileID) {
    this.profileID = profileID;
  }

  void setOnlineStatus(bool value) {
    this.isOnline = value;
  }

  bool getOnlineStatus() {
    return this.isOnline;
  }

  // void setFriends(List<String> friends) {
  //   this.friends = friends;
  // }

  // void setPendingFriends(List<String> pendingFriends) {
  //   this.pendingFriends = pendingFriends;
  // }

}
