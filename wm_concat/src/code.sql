-- 创建用户 
CREATE USER wmsys IDENTIFIED BY wmsys DEFAULT TABLESPACE isc; 

--授权用户
GRANT CONNECT,RESOURCE TO wmsys;

--以新建用户Login 
conn wmsys/wmsys


代码如下： 

-- 创建类型
CREATE OR REPLACE TYPE wm_concat_impl   
  AUTHID CURRENT_USER
AS OBJECT (
   curr_str   VARCHAR2 (32767),
   STATIC FUNCTION odciaggregateinitialize (sctx IN OUT wm_concat_impl)
      RETURN NUMBER,
   MEMBER FUNCTION odciaggregateiterate (
      SELF   IN OUT   wm_concat_impl,
      p1     IN       VARCHAR2
   )
      RETURN NUMBER,
   MEMBER FUNCTION odciaggregateterminate (
      SELF          IN       wm_concat_impl,
      returnvalue   OUT      VARCHAR2,
      flags         IN       NUMBER
   )
      RETURN NUMBER,
   MEMBER FUNCTION odciaggregatemerge (
      SELF    IN OUT   wm_concat_impl,
      sctx2   IN       wm_concat_impl
   )
      RETURN NUMBER
);
/

CREATE OR REPLACE TYPE BODY wm_concat_impl
IS
   STATIC FUNCTION odciaggregateinitialize (sctx IN OUT wm_concat_impl)
      RETURN NUMBER
   IS
   BEGIN
      sctx := wm_concat_impl (NULL);
      RETURN odciconst.success;
   END;
   MEMBER FUNCTION odciaggregateiterate (
      SELF   IN OUT   wm_concat_impl,
      p1     IN       VARCHAR2
   )
      RETURN NUMBER
   IS
   BEGIN
      IF (curr_str IS NOT NULL)
      THEN
         curr_str := curr_str || ',' || p1;
      ELSE
         curr_str := p1;
      END IF;

      RETURN odciconst.success;
   END;
   MEMBER FUNCTION odciaggregateterminate (
      SELF          IN       wm_concat_impl,
      returnvalue   OUT      VARCHAR2,
      flags         IN       NUMBER
   )
      RETURN NUMBER
   IS
   BEGIN
      returnvalue := curr_str;
      RETURN odciconst.success;
   END;
   MEMBER FUNCTION odciaggregatemerge (
      SELF    IN OUT   wm_concat_impl,
      sctx2   IN       wm_concat_impl
   )
      RETURN NUMBER
   IS
   BEGIN
      IF (sctx2.curr_str IS NOT NULL)
      THEN
         SELF.curr_str := SELF.curr_str || ',' || sctx2.curr_str;
      END IF;

      RETURN odciconst.success;
   END;
END;
/

CREATE OR REPLACE FUNCTION wm_concat (p1 VARCHAR2)
   RETURN VARCHAR2
   AGGREGATE USING wm_concat_impl;
/

--将wm_concat授权给所有人用
grant execute on wm_concat to public;
