"""
app/repositories/task_repository.py
-----------------------------------
Repository for task operations on Firestore.
Handles all CRUD operations for tasks.
"""

from datetime import datetime
from typing import Optional, List, Dict, Any
from core.firebase import db


class TaskRepository:
    """Repository for managing tasks in Firestore."""
    
    COLLECTION = "tasks"
    
    @staticmethod
    def create_task(
        owner_uid: str,
        title: str,
        description: Optional[str] = None,
        priority: str = "medium",
        deadline: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Create a new task in Firestore.
        
        Args:
            owner_uid: UID of the user creating the task
            title: Task title
            description: Optional task description
            priority: Priority level (low, medium, high)
            deadline: Optional deadline ISO string
            
        Returns:
            Dictionary with task data and ID
        """
        if not db:
            raise RuntimeError("Firebase not initialized")
        
        task_data = {
            "owner_uid": owner_uid,
            "title": title,
            "description": description or "",
            "priority": priority,
            "completed": False,
            "deadline": deadline,
            "created_at": datetime.utcnow().isoformat() + "Z",
            "updated_at": datetime.utcnow().isoformat() + "Z",
        }
        
        doc_ref = db.collection(TaskRepository.COLLECTION).document()
        doc_ref.set(task_data)
        
        task_data["id"] = doc_ref.id
        return task_data
    
    @staticmethod
    def get_task(task_id: str, owner_uid: str) -> Optional[Dict[str, Any]]:
        """
        Get a single task by ID.
        
        Args:
            task_id: Task document ID
            owner_uid: UID of the requesting user (for permission check)
            
        Returns:
            Task dictionary or None if not found
        """
        if not db:
            raise RuntimeError("Firebase not initialized")
        
        doc = db.collection(TaskRepository.COLLECTION).document(task_id).get()
        
        if not doc.exists:
            return None
        
        task = doc.to_dict()
        # Permission check - user can only view their own tasks
        if task.get("owner_uid") != owner_uid:
            return None
        
        task["id"] = task_id
        return task
    
    @staticmethod
    def get_user_tasks(
        owner_uid: str,
        status: Optional[str] = None,
        priority: Optional[str] = None,
        sort_by: str = "created_at",
        order: str = "desc",
        page: int = 1,
        page_size: int = 20,
    ) -> List[Dict[str, Any]]:
        """
        Get all tasks for a user with optional filtering and sorting.
        
        Args:
            owner_uid: UID of the user
            status: Optional filter for completed/pending
            priority: Optional priority filter (low, medium, high)
            sort_by: Field to sort by (created_at, deadline, title)
            order: Sort order (asc, desc)
            page: Page number (1-indexed)
            page_size: Number of items per page
            
        Returns:
            List of task dictionaries
        """
        if not db:
            raise RuntimeError("Firebase not initialized")
        
        query = db.collection(TaskRepository.COLLECTION).where("owner_uid", "==", owner_uid)
        
        # Apply filters
        if status == "completed":
            query = query.where("completed", "==", True)
        elif status == "pending":
            query = query.where("completed", "==", False)
        
        if priority:
            query = query.where("priority", "==", priority)
        
        # Apply sorting
        if order == "desc":
            query = query.order_by(sort_by, direction="DESCENDING")
        else:
            query = query.order_by(sort_by)
        
        docs = query.stream()
        tasks = []
        for doc in docs:
            task = doc.to_dict()
            task["id"] = doc.id
            tasks.append(task)
        
        # Paginate
        start_idx = (page - 1) * page_size
        end_idx = start_idx + page_size
        
        return tasks[start_idx:end_idx]
    
    @staticmethod
    def update_task(
        task_id: str,
        owner_uid: str,
        **updates
    ) -> Optional[Dict[str, Any]]:
        """
        Update a task.
        
        Args:
            task_id: Task document ID
            owner_uid: UID of the task owner (for permission check)
            **updates: Fields to update
            
        Returns:
            Updated task dictionary or None if not found
        """
        if not db:
            raise RuntimeError("Firebase not initialized")
        
        # Permission check
        doc = db.collection(TaskRepository.COLLECTION).document(task_id).get()
        if not doc.exists:
            return None
        
        task = doc.to_dict()
        if task.get("owner_uid") != owner_uid:
            return None
        
        # Update timestamp
        updates["updated_at"] = datetime.utcnow().isoformat() + "Z"
        
        db.collection(TaskRepository.COLLECTION).document(task_id).update(updates)
        
        # Return updated task
        updated_doc = db.collection(TaskRepository.COLLECTION).document(task_id).get()
        updated_task = updated_doc.to_dict()
        updated_task["id"] = task_id
        return updated_task
    
    @staticmethod
    def delete_task(task_id: str, owner_uid: str) -> bool:
        """
        Delete a task.
        
        Args:
            task_id: Task document ID
            owner_uid: UID of the task owner (for permission check)
            
        Returns:
            True if deleted, False if not found or permission denied
        """
        if not db:
            raise RuntimeError("Firebase not initialized")
        
        # Permission check
        doc = db.collection(TaskRepository.COLLECTION).document(task_id).get()
        if not doc.exists:
            return False
        
        task = doc.to_dict()
        if task.get("owner_uid") != owner_uid:
            return False
        
        db.collection(TaskRepository.COLLECTION).document(task_id).delete()
        return True
    
    @staticmethod
    def get_task_statistics(owner_uid: str) -> Dict[str, Any]:
        """
        Get task statistics for a user.
        
        Args:
            owner_uid: UID of the user
            
        Returns:
            Dictionary with task statistics
        """
        if not db:
            raise RuntimeError("Firebase not initialized")
        
        tasks = TaskRepository.get_user_tasks(owner_uid, page_size=1000)
        
        completed = sum(1 for t in tasks if t.get("completed"))
        pending = sum(1 for t in tasks if not t.get("completed"))
        
        # Count overdue tasks
        now = datetime.utcnow().isoformat() + "Z"
        overdue = sum(
            1 for t in tasks 
            if not t.get("completed") and t.get("deadline") and t.get("deadline") < now
        )
        
        # Count by priority
        high_priority = sum(1 for t in tasks if t.get("priority") == "high")
        
        return {
            "total": len(tasks),
            "completed": completed,
            "pending": pending,
            "overdue": overdue,
            "high_priority": high_priority,
        }
