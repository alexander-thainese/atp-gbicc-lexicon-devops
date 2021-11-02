

ALTER PROCEDURE [dbo].[CMT_GET_SINGLE_SCHEMA_TREE]
(@COUNTRY_CODE NVARCHAR(6), 
 @SCHEMA       UNIQUEIDENTIFIER
)
AS
    BEGIN

        DECLARE @COUNTRY_ID UNIQUEIDENTIFIER

        SELECT 
               @COUNTRY_ID = OBJECT_ID
        FROM CMT_COUNTRY
        WHERE CODE = @COUNTRY_CODE;

        WITH PARENTS
             AS (SELECT 
                        v.OBJECT_ID, 
                        V.TEXT_VALUE PARENT_NAME, 
                        V.TEXT_VALUE NAME, 
                        4 TYPE, 
                        CAST(NULL AS UNIQUEIDENTIFIER) PARENT_ID, 
                        V.VALUE_LIST_ID AS VALUE_LIST_ID, 
                        V.CHILD_LIST_ID PARENT_LIST_ID, 
                        se.SCHEMA_ID [ROOT_ID], 
                        E.OBJECT_ID AS ELEMENT_ID, 
                        1 [LEVEL], 
                        e.readonly, 
                        v.OBJECT_ID VALUE_ID, 
                        v.STATUS, 
                        v.GLOBAL_CODE, 
                        v.COUNTRY_ID, 
                        v.PARENT_ID PARENT_VALUE_ID
                 FROM CMT_VALUE V
                      LEFT JOIN CMT_METADATA_ELEMENT E ON E.VALUE_LIST_ID = V.VALUE_LIST_ID
                      JOIN CMT_METADATA_SCHEMA_ELEMENT SE ON SE.ELEMENT_ID = E.OBJECT_ID
                                                             AND SE.SCHEMA_ID = @SCHEMA
                 WHERE v.EXTERNAL_ID IS NULL
                       OR v.COUNTRY_ID = @COUNTRY_ID),
             CHILDREN
             AS (SELECT 
                        V.OBJECT_ID, 
                        VLH.NAME PARENT_NAME, 
                        V.TEXT_VALUE, 
                        4 TYPE, 
                        VLH.OBJECT_ID AS ValueList_ID, 
                        VLH.VALUE_LIST_ID, 
                        V.CHILD_LIST_ID, 
                        VLH.ROOT_ID, 
                        VLH.ELEMENT_ID, 
                        VLH.LEVEL + 1 AS Level, 
                        vlh.READONLY, 
                        V.OBJECT_ID VALUE_ID, 
                        v.STATUS, 
                        v.GLOBAL_CODE, 
                        v.COUNTRY_ID, 
                        v.PARENT_ID PARENT_VALUE_ID
                 FROM PARENTS VLH
                      INNER JOIN CMT_VALUE V ON VLH.PARENT_LIST_ID = V.VALUE_LIST_ID
                 WHERE v.EXTERNAL_ID IS NULL
                       OR v.COUNTRY_ID = @COUNTRY_ID),
             VALUE_LIST_HIERARCHY
             AS (SELECT 
                        OBJECT_ID, 
                        PARENT_NAME, 
                        NAME, 
                        4 TYPE, 
                        CAST(NULL AS UNIQUEIDENTIFIER) PARENT_ID, 
                        VALUE_LIST_ID, 
                        PARENT_LIST_ID, 
                        [ROOT_ID], 
                        ELEMENT_ID, 
                        1 [LEVEL], 
                        readonly, 
                        VALUE_ID, 
                        STATUS, 
                        GLOBAL_CODE, 
                        COUNTRY_ID, 
                        PARENT_ID PARENT_VALUE_ID
                 FROM PARENTS
                 UNION ALL
                 SELECT 
                        OBJECT_ID, 
                        PARENT_NAME, 
                        TEXT_VALUE, 
                        4 TYPE, 
                        ValueList_ID, 
                        VALUE_LIST_ID, 
                        CHILD_LIST_ID, 
                        ROOT_ID, 
                        ELEMENT_ID, 
                        LEVEL + 1 AS Level, 
                        READONLY, 
                        OBJECT_ID VALUE_ID, 
                        STATUS, 
                        GLOBAL_CODE, 
                        COUNTRY_ID, 
                        PARENT_VALUE_ID
                 FROM CHILDREN),
             TRANSLATED_VALUES
             AS (SELECT 
                        SCHEMA_ID, 
                        ELEMENT_ID, 
                        COUNT(DISTINCT ELEMENTS_VALUES.VALUE_ID) [ALL], 
                        SUM(CASE
                                WHEN ELEMENTS_VALUES.VALUE_DETAIL_ID IS NOT NULL
                                THEN 1
                                ELSE 0
                            END) TRANSLATED
                 FROM
                 (
                     SELECT DISTINCT 
                            VLH.ROOT_ID SCHEMA_ID, 
                            VLH.ELEMENT_ID, 
                            v.OBJECT_ID VALUE_ID, 
                            VD.VALUE_ID VALUE_DETAIL_ID
                     FROM VALUE_LIST_HIERARCHY VLH
                          INNER JOIN CMT_METADATA_ELEMENT e ON e.OBJECT_ID = VLH.ELEMENT_ID
                          INNER JOIN CMT_METADATA_SCHEMA S ON S.OBJECT_ID = VLH.ROOT_ID --acha
                          INNER JOIN CMT_VALUE V ON V.OBJECT_ID = VLH.VALUE_ID
                                                    AND V.STATUS > 0
                          LEFT JOIN CMT_VALUE_DETAIL VD ON VD.VALUE_ID = V.OBJECT_ID
                                                           AND @COUNTRY_ID = VD.COUNTRY_ID
                     WHERE e.STATUS > 0 --acha
                 ) ELEMENTS_VALUES
                 GROUP BY 
                          ELEMENTS_VALUES.SCHEMA_ID, 
                          ELEMENTS_VALUES.ELEMENT_ID)
                         SELECT 
                    NULL UNIQUE_ID, 
					    [VALUES].OBJECT_ID, 
                        [VALUES].NAME, 
                        [VALUES].GLOBAL_CODE, 
                        [VALUES].ALL_VALUES, 
                       [VALUES].LOCAL_VALUES, 
                       [VALUES].TYPE, 
                        [VALUES].PARENT_ID, 
                        [VALUES].CHANNEL, 
                     [VALUES].IS_ACTIVE, 
                
                                  CASE WHEN VALUE_PARENTS.PARENT_VALUE_ID IS NOT NULL THEN VALUE_PARENTS.PARENT_VALUE ELSE  [VALUES].LOCAL_VALUE END AS LOCAL_VALUE, 
								  CASE WHEN VALUE_PARENTS.PARENT_VALUE_ID IS NOT NULL THEN VALUE_PARENTS.PARENT_CODE ELSE  [VALUES].LOCAL_CODE END AS LOCAL_CODE, 
             
                        [VALUES].LEVEL, 
                        [VALUES].ELEMENT_ID, 
                       [VALUES].IS_LOV, 
                       [VALUES].LEVEL_NAME, 
                       [VALUES].[READONLY], 
                        [VALUES].DESCRIPTION, 
                        [VALUES].ACTIVATED_BY, 
                        [VALUES].ACTIVATION_DATE, 
                        [VALUES].DEFINED_BY, 
                        [VALUES].DEFINITION_DATE, 
                        [VALUES].DEACTIVATED_BY, 
                        [VALUES].DEACTIVATION_DATE, 
						 [VALUES].[ROOT_ID], 
                        [VALUES].DATA_TYPE, 
                       [VALUES].ATTRIBUTES, 
                        [VALUES].DEFAULT_VALUE, 
                       [VALUES].IS_REQUIRED,

                    ISNULL(v.TEXT_VALUE, [VALUES].DEFAULT_VALUE) DEFAULT_VALUE_TEXT, 
                    CAST(ISNULL(VALUE_TAGS.HAS_TAGS, 0) AS BIT) HAS_TAGS,
					VALUE_PARENTS.PARENT_VALUE_ID
             FROM
             (
                 SELECT 
                        VLH.OBJECT_ID, 
                       VLH.NAME, 
                        VLH.GLOBAL_CODE, 
                        NULL ALL_VALUES, 
                        NULL LOCAL_VALUES, 
                        3 TYPE, 
                        COALESCE(VLH.PARENT_ID, VLH.ELEMENT_ID) PARENT_ID, 
                        NULL CHANNEL, 
                        CAST(vlh.STATUS AS BIT) IS_ACTIVE, 
					
                        ISNULL(vd.VALUE,
                                  CASE
                                      WHEN vlh.COUNTRY_ID IS NULL
                                      THEN NULL
                                      ELSE ISNULL(v.TEXT_VALUE, '(Undefined)')
                                  END) LOCAL_VALUE, 
                        COALESCE(vd.LOCAL_CODE, v.GLOBAL_CODE) LOCAL_CODE, 
                        VLH.LEVEL, 
                        VLH.ELEMENT_ID, 
                        NULL IS_LOV, 
                        VLL.NAME LEVEL_NAME, 
                        CAST(vlh.READONLY AS BIT) READONLY, 
                        NULL AS DESCRIPTION, 
                        NULL AS ACTIVATED_BY, 
                        NULL AS ACTIVATION_DATE, 
                        NULL AS DEFINED_BY, 
                        NULL AS DEFINITION_DATE, 
                        NULL DEACTIVATED_BY, 
                        NULL DEACTIVATION_DATE, 
                        vlh.ROOT_ID [ROOT_ID], 
                        NULL DATA_TYPE, 
                        NULL ATTRIBUTES, 
                        NULL DEFAULT_VALUE, 
                        NULL IS_REQUIRED
                 FROM
                 (
                     SELECT 
                            vlh.object_id, 
                            MAX(vlh.name) name, 
                            MAX(VLH.GLOBAL_CODE) GLOBAL_CODE, 
                            MAX(LEVEL) level, 
                            COALESCE(VLH.PARENT_ID, VLH.ELEMENT_ID) PARENT_ID, 
                            MAX(ELEMENT_ID) ELEMENT_ID, 
                            MAX(CAST(VLH.READONLY AS TINYINT)) [READONLY], 
                            MAX(VLH.VALUE_ID) VALUE_ID, 
                            ROOT_ID, 
                            MAX(vlh.STATUS) STATUS, 
                            COUNTRY_ID, 
                            MAX(parent_value_id) PARENT_VALUE_ID
                     FROM VALUE_LIST_HIERARCHY vlh
                     WHERE COALESCE(VLH.PARENT_ID, VLH.ELEMENT_ID) IS NOT NULL
                     GROUP BY 
                              vlh.ROOT_ID, 
                              vlh.object_id, 
                              COALESCE(VLH.PARENT_ID, VLH.ELEMENT_ID), 
                              COUNTRY_ID
                 ) VLH
                 LEFT JOIN CMT_VALUE_DETAIL vd ON vd.VALUE_id = vlh.VALUE_ID
                                                  AND vd.COUNTRY_ID = @COUNTRY_ID
                 LEFT JOIN CMT_VALUE_LIST_LEVEL VLL ON VLL.Element_ID = VLH.ELEMENT_ID
                                                       AND VLL.LEVEL = VLH.level
                 LEFT JOIN CMT_VALUE V ON V.OBJECT_ID = VLH.PARENT_VALUE_ID
                 UNION ALL
                 SELECT 
                        S.OBJECT_ID, 
                        S.NAME, 
                        NULL, 
                        NULL, 
                        NULL, 
                        1, 
                        NULL, 
                        C.NAME, 
                        S.IS_ACTIVE, 
                        NULL, 
                        NULL, 
                        NULL, 
                        NULL, 
                        NULL, 
                        'Schema', 
                        0 READONLY, 
                        s.DESCRIPTION, 
                        s.ACTIVATED_BY, 
                        s.ACTIVATION_DATE, 
                        s.DEFINED_BY, 
                        s.DEFINITION_DATE, 
                        DEACTIVATED_BY, 
                        DEACTIVATION_DATE, 
                        s.OBJECT_ID, 
                        NULL, 
                        NULL ATTRIBUTES, 
                        NULL, 
                        NULL
                 FROM CMT_METADATA_SCHEMA S
                      INNER JOIN CMT_CHANNEL C ON C.OBJECT_ID = S.CHANNEL_ID
                 WHERE S.OBJECT_ID = @SCHEMA
                 UNION ALL
                 SELECT 
                        SE.ELEMENT_ID, 
                        e.NAME, 
                        NULL, 
                        tv.[ALL], 
                        tv.TRANSLATED TRANSLATED, 
                        2, 
                        SE.SCHEMA_ID, 
                        NULL, 
                        NULL, 
                        NULL, 
                        NULL, 
                        0, 
                        se.ELEMENT_ID, 
                        CAST(CASE
                                 WHEN et.NAME = 'LOV'
                                 THEN 1
                                 ELSE 0
                             END AS BIT), 
                        'Element', 
                        E.READONLY, 
                        NULL AS DESCRIPTION, 
                        NULL AS ACTIVATED_BY, 
                        NULL AS ACTIVATION_DATE, 
                        NULL AS DEFINED_BY, 
                        NULL AS DEFINITION_DATE, 
                        NULL DEACTIVATED_BY, 
                        NULL DEACTIVATION_DATE, 
                        se.SCHEMA_ID, 
                        ET.NAME, 
                        E.ATTRIBUTES, 
                        SE.DEFAULT_VALUE, 
                        SE.IS_REQUIRED
                 FROM CMT_METADATA_ELEMENT E
                      INNER JOIN CMT_METADATA_SCHEMA_ELEMENT SE ON SE.ELEMENT_ID = E.OBJECT_ID
                                                                   AND SE.SCHEMA_ID = @SCHEMA
                      INNER JOIN CMT_ELEMENT_TYPE ET ON ET.OBJECT_ID = E.TYPE_ID
                      LEFT JOIN TRANSLATED_VALUES TV ON E.OBJECT_ID = TV.ELEMENT_ID
                                                        AND se.SCHEMA_ID = tv.SCHEMA_ID
                 WHERE E.STATUS > 0
             ) [VALUES]
             LEFT JOIN CMT_VALUE v ON [VALUES].IS_LOV = 1
                                      AND CAST(v.OBJECT_ID AS NVARCHAR(40)) = [VALUES].DEFAULT_VALUE
             OUTER APPLY
             (
                 SELECT TOP 1 
                        CONVERT(BIT, 1) HAS_TAGS, 
                        VALUE_ID
                 FROM CMT_VALUE_TAG
                 WHERE VALUE_ID = [VALUES].OBJECT_ID
             ) VALUE_TAGS

				 LEFT OUTER JOIN 
             (
                 SELECT
				  c.OBJECT_ID ,
                      c.PARENT_ID PARENT_VALUE_ID,
					  p.TEXT_VALUE as PARENT_VALUE,
					  p.GLOBAL_CODE AS PARENT_CODE
                 FROM CMT_VALUE c INNER JOIN  CMT_VALUE p on c.PARENT_ID = p.OBJECT_ID
               
             ) VALUE_PARENTS ON VALUE_PARENTS.OBJECT_ID = [VALUES].OBJECT_ID
    END

		GO
	exec RegisterSchemaVersion '0.1.201118.00000.0'
GO