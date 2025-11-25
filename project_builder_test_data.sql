-- =====================================================
-- PROJECT BUILDER TEST DATA
-- =====================================================
-- Script untuk menambahkan test data yang lebih lengkap

-- 1. Clear existing test data (optional)
-- DELETE FROM project_step_completions;
-- DELETE FROM user_projects;
-- DELETE FROM project_templates;

-- 2. Insert comprehensive test templates
INSERT INTO project_templates (
    id,
    title, 
    description, 
    category, 
    difficulty_level, 
    estimated_hours, 
    project_steps, 
    tech_stack, 
    prerequisites,
    learning_objectives,
    resources,
    tags,
    is_featured,
    is_active
) VALUES 
(
    gen_random_uuid(),
    'Personal Portfolio Website',
    'Build a responsive personal portfolio website to showcase your skills and projects. Perfect for beginners learning web development.',
    'web',
    'beginner',
    12,
    '{
        "steps": [
            {
                "id": 1,
                "title": "Project Setup & Planning",
                "description": "Set up project structure, choose color scheme, and plan the layout",
                "estimatedHours": 2
            },
            {
                "id": 2,
                "title": "HTML Structure",
                "description": "Create the basic HTML structure with semantic elements",
                "estimatedHours": 3
            },
            {
                "id": 3,
                "title": "CSS Styling",
                "description": "Add CSS styles, make it responsive, and implement animations",
                "estimatedHours": 4
            },
            {
                "id": 4,
                "title": "JavaScript Interactivity",
                "description": "Add interactive elements like smooth scrolling and form validation",
                "estimatedHours": 2
            },
            {
                "id": 5,
                "title": "Testing & Deployment",
                "description": "Test across devices and deploy to GitHub Pages or Netlify",
                "estimatedHours": 1
            }
        ]
    }'::jsonb,
    '["HTML", "CSS", "JavaScript", "Responsive Design"]'::jsonb,
    '["Basic HTML knowledge", "CSS fundamentals"]'::jsonb,
    '["Create a professional portfolio", "Learn responsive design", "Practice modern CSS"]'::jsonb,
    '[
        {
            "title": "HTML & CSS Tutorial",
            "url": "https://www.w3schools.com/html/",
            "type": "tutorial"
        },
        {
            "title": "Responsive Design Guide",
            "url": "https://developer.mozilla.org/en-US/docs/Learn/CSS/CSS_layout/Responsive_Design",
            "type": "documentation"
        }
    ]'::jsonb,
    '["portfolio", "web", "beginner", "html", "css"]'::jsonb,
    true,
    true
),
(
    gen_random_uuid(),
    'Todo List App with React',
    'Build a full-featured todo list application using React with local storage persistence.',
    'web',
    'intermediate',
    16,
    '{
        "steps": [
            {
                "id": 1,
                "title": "React Setup",
                "description": "Set up React project with Create React App and install dependencies",
                "estimatedHours": 1
            },
            {
                "id": 2,
                "title": "Component Structure",
                "description": "Create component hierarchy and basic UI structure",
                "estimatedHours": 3
            },
            {
                "id": 3,
                "title": "State Management",
                "description": "Implement state management for todos using React hooks",
                "estimatedHours": 4
            },
            {
                "id": 4,
                "title": "CRUD Operations",
                "description": "Add create, read, update, and delete functionality",
                "estimatedHours": 4
            },
            {
                "id": 5,
                "title": "Local Storage",
                "description": "Implement data persistence using browser local storage",
                "estimatedHours": 2
            },
            {
                "id": 6,
                "title": "Styling & Polish",
                "description": "Add CSS styling and improve user experience",
                "estimatedHours": 2
            }
        ]
    }'::jsonb,
    '["React", "JavaScript", "CSS", "Local Storage"]'::jsonb,
    '["JavaScript ES6+", "Basic React knowledge", "HTML/CSS"]'::jsonb,
    '["Master React hooks", "Learn state management", "Practice component design"]'::jsonb,
    '[
        {
            "title": "React Documentation",
            "url": "https://reactjs.org/docs/getting-started.html",
            "type": "documentation"
        },
        {
            "title": "React Hooks Guide",
            "url": "https://reactjs.org/docs/hooks-intro.html",
            "type": "tutorial"
        }
    ]'::jsonb,
    '["react", "javascript", "intermediate", "frontend"]'::jsonb,
    true,
    true
),
(
    gen_random_uuid(),
    'REST API with Node.js',
    'Build a RESTful API using Node.js, Express, and MongoDB for a blog application.',
    'backend',
    'intermediate',
    20,
    '{
        "steps": [
            {
                "id": 1,
                "title": "Project Setup",
                "description": "Initialize Node.js project and install dependencies",
                "estimatedHours": 1
            },
            {
                "id": 2,
                "title": "Express Server",
                "description": "Set up Express server with basic middleware",
                "estimatedHours": 2
            },
            {
                "id": 3,
                "title": "Database Connection",
                "description": "Connect to MongoDB and set up data models",
                "estimatedHours": 3
            },
            {
                "id": 4,
                "title": "API Routes",
                "description": "Create CRUD routes for blog posts and users",
                "estimatedHours": 6
            },
            {
                "id": 5,
                "title": "Authentication",
                "description": "Implement JWT authentication and authorization",
                "estimatedHours": 4
            },
            {
                "id": 6,
                "title": "Error Handling",
                "description": "Add comprehensive error handling and validation",
                "estimatedHours": 2
            },
            {
                "id": 7,
                "title": "Testing & Documentation",
                "description": "Write tests and API documentation",
                "estimatedHours": 2
            }
        ]
    }'::jsonb,
    '["Node.js", "Express", "MongoDB", "JWT", "REST API"]'::jsonb,
    '["JavaScript fundamentals", "Basic Node.js knowledge", "Database concepts"]'::jsonb,
    '["Learn backend development", "Master API design", "Understand authentication"]'::jsonb,
    '[
        {
            "title": "Node.js Documentation",
            "url": "https://nodejs.org/en/docs/",
            "type": "documentation"
        },
        {
            "title": "Express.js Guide",
            "url": "https://expressjs.com/en/guide/routing.html",
            "type": "tutorial"
        }
    ]'::jsonb,
    '["nodejs", "backend", "api", "intermediate"]'::jsonb,
    false,
    true
),
(
    gen_random_uuid(),
    'Mobile App with Flutter',
    'Create a cross-platform mobile app using Flutter with Firebase backend.',
    'mobile',
    'advanced',
    30,
    '{
        "steps": [
            {
                "id": 1,
                "title": "Flutter Setup",
                "description": "Set up Flutter development environment and create project",
                "estimatedHours": 2
            },
            {
                "id": 2,
                "title": "UI Design",
                "description": "Design and implement the user interface with Material Design",
                "estimatedHours": 6
            },
            {
                "id": 3,
                "title": "State Management",
                "description": "Implement state management using Provider or Bloc",
                "estimatedHours": 4
            },
            {
                "id": 4,
                "title": "Firebase Integration",
                "description": "Set up Firebase and integrate authentication and database",
                "estimatedHours": 6
            },
            {
                "id": 5,
                "title": "Core Features",
                "description": "Implement main app functionality and business logic",
                "estimatedHours": 8
            },
            {
                "id": 6,
                "title": "Testing",
                "description": "Write unit tests and integration tests",
                "estimatedHours": 2
            },
            {
                "id": 7,
                "title": "Deployment",
                "description": "Build and deploy to app stores",
                "estimatedHours": 2
            }
        ]
    }'::jsonb,
    '["Flutter", "Dart", "Firebase", "Mobile Development"]'::jsonb,
    '["Dart programming", "Mobile development concepts", "Firebase basics"]'::jsonb,
    '["Master Flutter development", "Learn mobile app architecture", "Practice Firebase integration"]'::jsonb,
    '[
        {
            "title": "Flutter Documentation",
            "url": "https://flutter.dev/docs",
            "type": "documentation"
        },
        {
            "title": "Firebase for Flutter",
            "url": "https://firebase.flutter.dev/",
            "type": "tutorial"
        }
    ]'::jsonb,
    '["flutter", "mobile", "advanced", "firebase"]'::jsonb,
    true,
    true
),
(
    gen_random_uuid(),
    'Data Analysis with Python',
    'Analyze a real dataset using Python, pandas, and create visualizations.',
    'data',
    'intermediate',
    18,
    '{
        "steps": [
            {
                "id": 1,
                "title": "Environment Setup",
                "description": "Set up Python environment with Jupyter and required libraries",
                "estimatedHours": 1
            },
            {
                "id": 2,
                "title": "Data Collection",
                "description": "Find and download a suitable dataset for analysis",
                "estimatedHours": 2
            },
            {
                "id": 3,
                "title": "Data Cleaning",
                "description": "Clean and preprocess the data using pandas",
                "estimatedHours": 4
            },
            {
                "id": 4,
                "title": "Exploratory Analysis",
                "description": "Perform exploratory data analysis and find insights",
                "estimatedHours": 5
            },
            {
                "id": 5,
                "title": "Data Visualization",
                "description": "Create charts and graphs using matplotlib and seaborn",
                "estimatedHours": 4
            },
            {
                "id": 6,
                "title": "Report Creation",
                "description": "Document findings and create a comprehensive report",
                "estimatedHours": 2
            }
        ]
    }'::jsonb,
    '["Python", "Pandas", "Matplotlib", "Jupyter", "Data Analysis"]'::jsonb,
    '["Python basics", "Statistics fundamentals", "Basic data concepts"]'::jsonb,
    '["Learn data analysis", "Master pandas library", "Practice data visualization"]'::jsonb,
    '[
        {
            "title": "Pandas Documentation",
            "url": "https://pandas.pydata.org/docs/",
            "type": "documentation"
        },
        {
            "title": "Data Analysis Tutorial",
            "url": "https://www.kaggle.com/learn/pandas",
            "type": "tutorial"
        }
    ]'::jsonb,
    '["python", "data", "analysis", "intermediate"]'::jsonb,
    false,
    true
);

-- 3. Verify the data was inserted
SELECT 
    title,
    category,
    difficulty_level,
    estimated_hours,
    is_active,
    (project_steps->'steps')::jsonb as steps_count
FROM project_templates 
WHERE is_active = true
ORDER BY created_at DESC;

-- 4. Show total count
SELECT 
    'Total active templates: ' || COUNT(*)::text as summary
FROM project_templates 
WHERE is_active = true;

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================
SELECT 'Project Builder test data inserted successfully!' as status;