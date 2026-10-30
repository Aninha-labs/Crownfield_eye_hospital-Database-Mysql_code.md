SELECT s.StudentID,
       s.StudentName,
       c.CourseName,
       l.LecturerName
FROM Student s
INNER JOIN Course c   ON s.CourseID   = c.CourseID
INNER JOIN Lecturer l ON c.LecturerID = l.LecturerID;