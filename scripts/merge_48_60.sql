DELETE FROM expert_knowledge_chunks WHERE content_type = 'so_sanh' AND do_tuoi_thang_min = 48 AND do_tuoi_thang_max = 60;
DELETE FROM expert_knowledge_chunks WHERE do_tuoi_thang_min = 48 AND do_tuoi_thang_max = 71;
ATTACH '/data/data/com.iris.app.iris_app/app_flutter/temp_48_60.db' AS src;
INSERT OR REPLACE INTO expert_knowledge_chunks SELECT * FROM src.expert_knowledge_chunks;
DETACH src;
