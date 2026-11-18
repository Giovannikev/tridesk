-- P04 – Schéma des tickets, de la base de connaissances (pgvector) et des vues Grafana.
-- Exécuté une seule fois, à la création du volume Postgres.

CREATE EXTENSION IF NOT EXISTS vector;

-- ---------------------------------------------------------------------------
-- Tickets
-- ---------------------------------------------------------------------------
CREATE TABLE tickets (
    id                    bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    channel               text NOT NULL CHECK (channel IN ('webhook', 'email', 'telegram')),
    external_id           text,                -- Message-ID, update_id Telegram, référence client…
    customer_name         text,
    customer_contact      text,                -- e-mail ou chat_id Telegram
    subject               text,
    body                  text NOT NULL,

    status                text NOT NULL DEFAULT 'recu'
                          CHECK (status IN ('recu', 'classe', 'escalade', 'resolu')),

    -- Classification (LLM, sortie JSON structurée)
    category              text CHECK (category IN (
                              'acces_connexion', 'facturation_comptabilite', 'ventes_crm',
                              'achats_stock', 'import_export', 'technique_bug',
                              'hebergement_odoosh', 'autre')),
    priority              text CHECK (priority IN ('basse', 'normale', 'haute', 'critique')),
    confidence            numeric(4, 3) CHECK (confidence BETWEEN 0 AND 1),
    wants_human           boolean NOT NULL DEFAULT false,
    summary               text,
    classification_reason text,

    -- Réponse suggérée (RAG)
    suggested_answer      text,
    sources               jsonb NOT NULL DEFAULT '[]',
    answerable            boolean,
    final_answer          text,                -- réponse réellement envoyée au client
    answered_by           text CHECK (answered_by IN ('bot', 'humain')),

    -- Escalade
    escalated             boolean NOT NULL DEFAULT false,
    escalation_reasons    text[] NOT NULL DEFAULT '{}',
    resolved_by           text CHECK (resolved_by IN ('bot', 'humain')),
    resolution_note       text,

    llm_model             text,
    processing_error      text,
    is_demo               boolean NOT NULL DEFAULT false,   -- données fictives du script seed_demo.sql

    -- Horodatages du cycle de vie
    received_at           timestamptz NOT NULL DEFAULT now(),
    classified_at         timestamptz,
    answered_at           timestamptz,
    escalated_at          timestamptz,
    resolved_at           timestamptz,
    updated_at            timestamptz NOT NULL DEFAULT now(),

    UNIQUE (channel, external_id)
);

CREATE INDEX tickets_received_at_idx ON tickets (received_at);
CREATE INDEX tickets_status_idx ON tickets (status);

-- Journal : une ligne à chaque changement de statut (rempli par trigger)
CREATE TABLE ticket_events (
    id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ticket_id  bigint NOT NULL REFERENCES tickets (id) ON DELETE CASCADE,
    event      text NOT NULL,
    at         timestamptz NOT NULL DEFAULT now(),
    details    jsonb NOT NULL DEFAULT '{}'
);
CREATE INDEX ticket_events_ticket_idx ON ticket_events (ticket_id);

CREATE FUNCTION tickets_audit() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO ticket_events (ticket_id, event, at, details)
        VALUES (NEW.id, NEW.status, NEW.received_at, jsonb_build_object('channel', NEW.channel));
        RETURN NEW;
    END IF;
    NEW.updated_at := now();
    IF NEW.status IS DISTINCT FROM OLD.status THEN
        INSERT INTO ticket_events (ticket_id, event, details)
        VALUES (NEW.id, NEW.status, jsonb_build_object(
            'from', OLD.status, 'category', NEW.category, 'priority', NEW.priority,
            'escalation_reasons', NEW.escalation_reasons));
    END IF;
    RETURN NEW;
END $$;

CREATE TRIGGER tickets_audit_ins AFTER INSERT ON tickets
    FOR EACH ROW EXECUTE FUNCTION tickets_audit();
CREATE TRIGGER tickets_audit_upd BEFORE UPDATE ON tickets
    FOR EACH ROW EXECUTE FUNCTION tickets_audit();

-- État des canaux (ex. dernier update_id Telegram traité)
CREATE TABLE channel_state (
    key        text PRIMARY KEY,
    value      text NOT NULL,
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------------
-- Base de connaissances (RAG)
-- La dimension n'est pas figée : elle dépend du modèle d'embeddings (bge-m3 = 1024).
-- Changer de modèle => relancer l'ingestion (qui vide la table).
-- ---------------------------------------------------------------------------
CREATE TABLE kb_chunks (
    id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    doc_path     text NOT NULL,
    doc_title    text NOT NULL,
    section      text,
    chunk_index  int  NOT NULL,
    content      text NOT NULL,
    embedding    vector NOT NULL,
    model        text NOT NULL,
    ingested_at  timestamptz NOT NULL DEFAULT now(),
    UNIQUE (doc_path, chunk_index)
);

-- Recherche des k extraits les plus proches (similarité cosinus)
CREATE FUNCTION match_kb(query_embedding vector, k int DEFAULT 4)
RETURNS TABLE (doc_path text, doc_title text, section text, content text, similarity numeric)
LANGUAGE sql STABLE AS $$
    SELECT c.doc_path, c.doc_title, c.section, c.content,
           round((1 - (c.embedding <=> query_embedding))::numeric, 3) AS similarity
    FROM kb_chunks c
    ORDER BY c.embedding <=> query_embedding
    LIMIT k;
$$;

-- ---------------------------------------------------------------------------
-- Vues pour Grafana (délais en secondes)
-- ---------------------------------------------------------------------------
CREATE VIEW v_ticket_durations AS
SELECT t.id, t.channel, t.category, t.priority, t.status, t.escalated, t.is_demo,
       t.answered_by, t.resolved_by, t.received_at,
       EXTRACT(EPOCH FROM t.classified_at - t.received_at) AS classification_s,
       EXTRACT(EPOCH FROM t.answered_at   - t.received_at) AS first_response_s,
       EXTRACT(EPOCH FROM t.escalated_at  - t.received_at) AS escalation_s,
       EXTRACT(EPOCH FROM t.resolved_at   - t.received_at) AS resolution_s
FROM tickets t;
