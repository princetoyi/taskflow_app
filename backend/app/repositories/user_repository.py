"""
app/repositories/user_repository.py
-----------------------------------
Repository for user operations on Firestore.
"""

from datetime import datetime
from typing import Optional, List, Dict, Any
from core.firebase import db


class UserRepository:
    """Repository for managing users in Firestore."""
    
    COLLECTION = "users"
    
    @staticmethod
    def create_user(
        uid: str,
        email: str,
        display_name: Optional[str] = None,
        role: str = "employee",
    ) -> Dict[str, Any]:
        """
        Create a user record in Firestore.
        
        Args:
            uid: Firebase UID
            email: User email
            display_name: Optional display name
            role: User role (employee, manager, admin)
            
        Returns:
            User dictionary
        """
        if not db:
            raise RuntimeError("Firebase not initialized")
        
        user_data = {
            "uid": uid,
            "email": email,
            "display_name": display_name or "",
            "role": role,
            "is_active": True,
            "created_at": datetime.utcnow().isoformat() + "Z",
            "updated_at": datetime.utcnow().isoformat() + "Z",
        }
        
        db.collection(UserRepository.COLLECTION).document(uid).set(user_data)
        return user_data
    
    @staticmethod
    def get_user(uid: str) -> Optional[Dict[str, Any]]:
        """
        Get user by UID.
        
        Args:
            uid: Firebase UID
            
        Returns:
            User dictionary or None
        """
        if not db:
            raise RuntimeError("Firebase not initialized")
        
        doc = db.collection(UserRepository.COLLECTION).document(uid).get()
        
        if not doc.exists:
            return None
        
        user = doc.to_dict()
        user["uid"] = uid
        return user
    
    @staticmethod
    def update_user(uid: str, **updates) -> Optional[Dict[str, Any]]:
        """
        Update user.
        
        Args:
            uid: Firebase UID
            **updates: Fields to update
            
        Returns:
            Updated user dictionary or None
        """
        if not db:
            raise RuntimeError("Firebase not initialized")
        
        # Check if user exists
        doc = db.collection(UserRepository.COLLECTION).document(uid).get()
        if not doc.exists:
            return None
        
        updates["updated_at"] = datetime.utcnow().isoformat() + "Z"
        
        db.collection(UserRepository.COLLECTION).document(uid).update(updates)
        
        # Return updated user
        updated_doc = db.collection(UserRepository.COLLECTION).document(uid).get()
        user = updated_doc.to_dict()
        user["uid"] = uid
        return user
    
    @staticmethod
    def get_team_members(manager_uid: str) -> List[Dict[str, Any]]:
        """
        Get all team members managed by a manager.
        
        Args:
            manager_uid: UID of the manager
            
        Returns:
            List of team member dictionaries
        """
        if not db:
            raise RuntimeError("Firebase not initialized")
        
        # Get all employees in the team (those created by this manager)
        # In a real app, you'd have a team_id field to group users
        query = db.collection(UserRepository.COLLECTION).where("role", "==", "employee")
        
        docs = query.stream()
        users = []
        for doc in docs:
            user = doc.to_dict()
            user["uid"] = doc.id
            users.append(user)
        
        return users
    
    @staticmethod
    def list_users(role: Optional[str] = None) -> List[Dict[str, Any]]:
        """
        List all users, optionally filtered by role.
        
        Args:
            role: Optional role filter (employee, manager, admin)
            
        Returns:
            List of user dictionaries
        """
        if not db:
            raise RuntimeError("Firebase not initialized")
        
        if role:
            query = db.collection(UserRepository.COLLECTION).where("role", "==", role)
        else:
            query = db.collection(UserRepository.COLLECTION)
        
        docs = query.stream()
        users = []
        for doc in docs:
            user = doc.to_dict()
            user["uid"] = doc.id
            users.append(user)
        
        return users
