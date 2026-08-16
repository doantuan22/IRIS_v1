DELETE FROM expert_knowledge_chunks WHERE content_type = 'so_sanh' AND do_tuoi_thang_min = 24 AND do_tuoi_thang_max = 47;
DELETE FROM expert_knowledge_chunks WHERE id = 'ffe04570-6163-4914-aeaf-10d30c320211';
ATTACH '/data/data/com.iris.app.iris_app/app_flutter/temp_24_47.db' AS src;
INSERT OR REPLACE INTO expert_knowledge_chunks SELECT * FROM src.expert_knowledge_chunks;
DETACH src;
