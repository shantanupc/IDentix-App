# Backend Changes Required

This document outlines the backend changes needed to support the security improvements implemented in the Flutter frontend.

## 1. Remove Original Hash from API Response

**File:** `routes/user.js` (or equivalent user API endpoint)

**Current Behavior:**
- The `GET /api/user/:id` endpoint returns the `blockchain_hash` (original hash) to the frontend
- This is a security risk as it allows users to potentially recreate the dynamic hash

**Required Changes:**

```javascript
// BEFORE (Insecure):
res.json({
  success: true,
  data: {
    user_id: user.user_id,
    name: user.name,
    blockchain_hash: user.blockchain_hash,  // ❌ REMOVE THIS
    transaction_hash: user.transaction_hash,
    block_number: user.block_number,
    // ... other fields
  }
});

// AFTER (Secure):
res.json({
  success: true,
  data: {
    user_id: user.user_id,
    name: user.name,
    // blockchain_hash: user.blockchain_hash,  // ❌ DO NOT SEND
    transaction_hash: user.transaction_hash,
    block_number: user.block_number,
    // ... other fields
  }
});
```

**Important Notes:**
- The backend should **still store and use** the original hash internally for verification
- Only **remove it from the API response** to the frontend
- The `verifyTimestamp` endpoint should continue to use the original hash for verification logic

---

## 2. Enhanced Verification Response with User Attributes

**File:** `routes/verify.js` (or equivalent verification API endpoint)

**Current Behavior:**
- Verification endpoint returns minimal information (verified: true/false, reason)
- Frontend needs actual user data to display specific verification results

**Required Changes:**

### Update `POST /api/verify-timestamp` endpoint:

```javascript
// BEFORE (Incomplete):
res.json({
  success: true,
  data: {
    verified: true,
    reason: "QR code verified successfully",
    timeRemaining: timeRemaining
  }
});

// AFTER (Complete with user data):
res.json({
  success: true,
  data: {
    verified: true,
    reason: "QR code verified successfully",
    timeRemaining: timeRemaining,
    userData: {
      name: user.name,
      user_id: user.user_id,
      age: user.age,
      branch: user.additional_attributes?.branch,
      year: user.additional_attributes?.year,
      session: user.additional_attributes?.session,
      // DO NOT include: blockchain_hash, password, or sensitive internal data
    }
  }
});
```

**Fields to Include in `userData`:**
- `name` - User's full name
- `user_id` - User ID
- `age` - User's age (for age verification)
- `branch` - Branch/department (from additional_attributes)
- `year` - Academic year (from additional_attributes)
- `session` - Academic session (from additional_attributes)

**Fields to EXCLUDE:**
- ❌ `blockchain_hash` (original hash)
- ❌ `password` or password hash
- ❌ Internal database IDs
- ❌ Any other sensitive information

---

## 3. Security Best Practices

### Verification Logic (Must Remain Unchanged):

```javascript
// Backend verification logic (KEEP THIS):
const originalHash = user.blockchain_hash; // Retrieved from database
const dynamicHash = crypto
  .createHash('sha256')
  .update(`${originalHash}:${timestamp}`)
  .digest('hex');

if (dynamicHash === receivedDynamicHash) {
  // Verification successful
  // Return user data (as shown in section 2)
}
```

### Key Points:
1. **Backend** continues to use `originalHash` for verification internally
2. **Frontend** never receives or stores the `originalHash`
3. **Dynamic hash** is generated on-the-fly for each QR code
4. **User attributes** are only sent after successful verification

---

## 4. Testing Checklist

After implementing backend changes, verify:

- [ ] GET `/api/user/:id` does NOT return `blockchain_hash`
- [ ] POST `/api/verify-timestamp` still correctly verifies dynamic hash
- [ ] POST `/api/verify-timestamp` returns `userData` object with required fields
- [ ] Verification logic correctly uses stored `blockchain_hash` internally
- [ ] No sensitive data (passwords, internal IDs) is exposed in any API response
- [ ] Frontend can display actual user data in verification result screen

---

## 5. Example API Response Format

### GET `/api/user/:id` Response:
```json
{
  "success": true,
  "data": {
    "user_id": "USR001",
    "name": "Rahul Kumar",
    "age": 21,
    "id_number": "XXXX-XXXX-1234",
    "transaction_hash": "0xabc123...",
    "block_number": "12345678",
    "additional_attributes": {
      "branch": "Information Technology",
      "year": "Final Year",
      "session": "2021-2025",
      "gender": "Male"
    }
  }
}
```

### POST `/api/verify-timestamp` Response (Success):
```json
{
  "success": true,
  "data": {
    "verified": true,
    "reason": "QR code verified successfully",
    "timeRemaining": 25,
    "userData": {
      "name": "Rahul Kumar",
      "user_id": "USR001",
      "age": 21,
      "branch": "Information Technology",
      "year": "Final Year",
      "session": "2021-2025"
    }
  }
}
```

---

## Summary

**Critical Security Change:**
- ❌ REMOVE `blockchain_hash` from GET `/api/user/:id` response
- ✅ KEEP using `blockchain_hash` internally for verification

**Enhanced Functionality:**
- ✅ ADD `userData` object to verification response
- ✅ INCLUDE relevant user attributes (name, age, branch, year, session)
- ❌ NEVER expose sensitive data (passwords, original hash, internal IDs)

These changes ensure:
1. **Security**: Original hash cannot be reconstructed by users
2. **Functionality**: Frontend can display meaningful verification results
3. **Privacy**: Only necessary information is shared after successful verification
