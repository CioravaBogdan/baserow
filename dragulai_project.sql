-- Baza de date SQLite pentru Proiectul DraculAI
-- Pentru tracking și organizarea conținutului viral

-- Tabel pentru Character Bible & Design
CREATE TABLE IF NOT EXISTS character_bible (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nume_complet TEXT NOT NULL,
    varsta INTEGER,
    tagline TEXT,
    descriere_fizica TEXT,
    paleta_culori TEXT,
    expresii_faciale TEXT,
    outfit_principal TEXT,
    trasaturi_personalitate TEXT,
    backstory TEXT,
    status_implementare TEXT CHECK(status_implementare IN ('Draft', 'În lucru', 'Finalizat')) DEFAULT 'Draft',
    data_creare DATETIME DEFAULT CURRENT_TIMESTAMP,
    data_actualizare DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Tabel pentru Scripturi & Episoade
CREATE TABLE IF NOT EXISTS scripturi_episoade (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    titlu_episod TEXT NOT NULL,
    tip_content TEXT CHECK(tip_content IN ('Full Episode', 'Short', 'TikTok', 'Instagram Reel')) DEFAULT 'Short',
    script_complet TEXT,
    durata_estimata TEXT,
    teme_abordate TEXT, -- JSON array as text
    status TEXT CHECK(status IN ('Draft', 'Finalizat', 'Publicat')) DEFAULT 'Draft',
    data_planificata DATE,
    thumbnail_description TEXT,
    tags_hashtags TEXT,
    data_creare DATETIME DEFAULT CURRENT_TIMESTAMP,
    data_actualizare DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Tabel pentru Ideas & Concepts
CREATE TABLE IF NOT EXISTS ideas_concepts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    titlu_idee TEXT NOT NULL,
    categorie TEXT CHECK(categorie IN ('Story', 'Visual', 'Technical', 'Marketing')) DEFAULT 'Story',
    descriere TEXT,
    prioritate TEXT CHECK(prioritate IN ('Low', 'Medium', 'High', 'Critical')) DEFAULT 'Medium',
    status TEXT CHECK(status IN ('New', 'In Review', 'Approved', 'Rejected', 'Implemented')) DEFAULT 'New',
    tags TEXT,
    data_adaugare DATETIME DEFAULT CURRENT_TIMESTAMP,
    data_implementare DATETIME
);

-- Tabel pentru Performance Tracking
CREATE TABLE IF NOT EXISTS content_performance (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    episod_id INTEGER,
    platforma TEXT CHECK(platforma IN ('TikTok', 'Instagram', 'YouTube', 'Facebook')) NOT NULL,
    views INTEGER DEFAULT 0,
    likes INTEGER DEFAULT 0,
    comments INTEGER DEFAULT 0,
    shares INTEGER DEFAULT 0,
    saves INTEGER DEFAULT 0,
    engagement_rate REAL DEFAULT 0.0,
    data_publicare DATETIME,
    data_masurare DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (episod_id) REFERENCES scripturi_episoade(id)
);

-- Tabel pentru Viral Trends Tracking
CREATE TABLE IF NOT EXISTS viral_trends (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    trend_name TEXT NOT NULL,
    descriere TEXT,
    hashtags TEXT,
    popularitate_score INTEGER DEFAULT 0,
    data_descoperire DATETIME DEFAULT CURRENT_TIMESTAMP,
    data_expirare DATETIME,
    status TEXT CHECK(status IN ('Active', 'Declining', 'Expired')) DEFAULT 'Active',
    potential_viral TEXT CHECK(potential_viral IN ('Low', 'Medium', 'High', 'Viral')) DEFAULT 'Medium'
);

-- Triggers pentru actualizare automată timestamp
CREATE TRIGGER IF NOT EXISTS update_character_bible_timestamp 
    AFTER UPDATE ON character_bible
    BEGIN
        UPDATE character_bible SET data_actualizare = CURRENT_TIMESTAMP WHERE id = NEW.id;
    END;

CREATE TRIGGER IF NOT EXISTS update_scripturi_timestamp 
    AFTER UPDATE ON scripturi_episoade
    BEGIN
        UPDATE scripturi_episoade SET data_actualizare = CURRENT_TIMESTAMP WHERE id = NEW.id;
    END;

-- Views pentru rapoarte
CREATE VIEW IF NOT EXISTS content_summary AS
SELECT 
    'Character Bible' as tip_content,
    COUNT(*) as total_items,
    SUM(CASE WHEN status_implementare = 'Finalizat' THEN 1 ELSE 0 END) as finalizate,
    SUM(CASE WHEN status_implementare = 'În lucru' THEN 1 ELSE 0 END) as in_lucru,
    SUM(CASE WHEN status_implementare = 'Draft' THEN 1 ELSE 0 END) as draft
FROM character_bible
UNION ALL
SELECT 
    'Episoade',
    COUNT(*),
    SUM(CASE WHEN status = 'Publicat' THEN 1 ELSE 0 END),
    SUM(CASE WHEN status = 'Finalizat' THEN 1 ELSE 0 END),
    SUM(CASE WHEN status = 'Draft' THEN 1 ELSE 0 END)
FROM scripturi_episoade
UNION ALL
SELECT 
    'Ideas',
    COUNT(*),
    SUM(CASE WHEN status = 'Implemented' THEN 1 ELSE 0 END),
    SUM(CASE WHEN status = 'Approved' THEN 1 ELSE 0 END),
    SUM(CASE WHEN status = 'New' THEN 1 ELSE 0 END)
FROM ideas_concepts;

-- Inserare date inițiale pentru DraculAI
INSERT OR IGNORE INTO character_bible (
    nume_complet, varsta, tagline, descriere_fizica, paleta_culori, 
    expresii_faciale, outfit_principal, trasaturi_personalitate, backstory
) VALUES (
    'Dracula AI',
    500,
    'De 500 de ani învăț umorul uman... încă nu înțeleg de ce râdeți la meme-uri!',
    'Vampir clasic cu umor negru, canini proeminenți, ochi roșii expresivi pentru reacții comice',
    'Negru, roșu, alb - paleta clasică gotică cu accente moderne',
    'Confuzie adorabilă, sarcasm elegant, surpriză genuină la trendurile moderne',
    'Capă clasică dar adaptată modern, guler înalt, detalii contemporane subtile',
    'Sarcastic dar iubitor, confuz de modernitate, dornic să învețe, umor autocritizant',
    'Vampir de 500 de ani care încearcă să se adapteze la era digitală și să înțeleagă umorul modern'
);

INSERT OR IGNORE INTO ideas_concepts (titlu_idee, categorie, descriere, prioritate) VALUES 
('Primul episod de introducere', 'Story', 'DraculAI se prezintă și explică de ce vrea să facă content viral', 'High'),
('Reacții la TikTok trends', 'Content', 'DraculAI reactionează la trendurile actuale cu confuzie amuzantă', 'High'),
('Dracula încearcă să comande mâncare online', 'Story', 'Comedic take pe tehnologia modernă vs vampir vechi', 'Medium'),
('Setup pentru recording', 'Technical', 'Configurare cameră, lighting, background pentru character', 'Critical'),
('Voice design', 'Technical', 'Dezvoltarea vocii distinctive pentru DraculAI', 'High');

-- Index-uri pentru performance
CREATE INDEX IF NOT EXISTS idx_character_status ON character_bible(status_implementare);
CREATE INDEX IF NOT EXISTS idx_episoade_status ON scripturi_episoade(status);
CREATE INDEX IF NOT EXISTS idx_ideas_prioritate ON ideas_concepts(prioritate);
CREATE INDEX IF NOT EXISTS idx_performance_platforma ON content_performance(platforma);
CREATE INDEX IF NOT EXISTS idx_trends_status ON viral_trends(status);
