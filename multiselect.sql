USE Earth_New;
SELECT 'vCAS' AS table_name, count (*) from super.vCAS
UNION
SELECT 'vCAS5' AS table_name, count (*) from super.vCAS5
UNION
SELECT 'vCAS2_ZM' AS table_name, count (*) from super.vCAS2_ZM
UNION
SELECT 'vCASv2_CC' AS table_name, count (*) from super.vCASv2_CC
UNION
SELECT 'vCAS2_SC' AS table_name, count (*) from super.vCAS2_SC
UNION
SELECT 'vCAS3' AS table_name, count (*) from super.vCAS3
UNION
SELECT 'vCASv3_CC' AS table_name, count (*) from super.vCASv3_CC
UNION
SELECT 'vCAS4_IKM_EXCL_CAM_CIP' AS table_name, count (*) from super.vCAS4_IKM_EXCL_CAM_CIP
UNION
SELECT 'vCAS4_EXCL_CAM_CIP' AS table_name, count (*) from super.vCAS4_EXCL_CAM_CIP
UNION
SELECT 'vCAS4_IKM_CAM_CIP' AS table_name, count (*) from super.vCAS4_IKM_CAM_CIP
UNION
SELECT 'vCAS4_CAM_CIP' AS table_name, count (*) from super.vCAS4_CAM_CIP;