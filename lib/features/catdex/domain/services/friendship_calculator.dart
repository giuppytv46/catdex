class FriendshipCalculator {
  const FriendshipCalculator();

  int levelForPoints(int friendshipPoints) {
    if (friendshipPoints >= 500) {
      return 5;
    }
    if (friendshipPoints >= 260) {
      return 4;
    }
    if (friendshipPoints >= 120) {
      return 3;
    }
    if (friendshipPoints >= 40) {
      return 2;
    }

    return 1;
  }
}
