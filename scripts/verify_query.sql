SELECT linh_vuc, count(*) FROM expert_knowledge_chunks WHERE content_type='so_sanh' AND do_tuoi_thang_min=24 AND do_tuoi_thang_max=47 GROUP BY linh_vuc ORDER BY linh_vuc;
