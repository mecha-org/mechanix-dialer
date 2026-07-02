enum CallStatus { none, calling, incoming, active, cancelled }

enum ContactsStatus { initial, loading, loaded, error }

enum CallFilter { all, missed }

enum RecentCallsStatus { initial, loading, loaded, error }

enum CallType { incoming, outgoing, missed, rejected, blocked }

enum ContactsError {
  loadFailed,
  saveFailed,
  deleteFailed,
  storeUnavailable,
  unknown,
  updateFailed,
  searchFailed,
  duplicateContact,
}
