# 遇到的问题
Oracle 11g XE 部署一个已有的应用，发现在该应用的建库脚本及应用中的数据库访问中都有使用函数 WMSYS.WM_CONCAT。 经过查资料发现这是一个标准版的内部函数，不推荐使用的。

# 对策分析
- 首先，最好不用wm_concat, 如下图所说，使用了移植性将无法保证。
![wm_concat.png](http://github.com/wangmengqiang001/blogs/tree/master/wm_concat/images/wm_concat.png)

- 其次， 可以LISTAGG 来代替
在如下的示例中
````
with temp as(
select 'China' nation ,'Guangzhou' city from dual union all  
select 'China' nation ,'Shanghai' city from dual union all  
select 'China' nation ,'Beijing' city from dual union all  
select 'USA' nation ,'New York' city from dual union all  
select 'USA' nation ,'Bostom' city from dual union all  
select 'Japan' nation ,'Tokyo' city from dual   
)
select nation,listagg(nation||';'||city,',') within GROUP (order by city)  as Cities
from temp  
group by nation;
````
输出的结果

|nation | Cities |
|------|------|
|China | China;Beijing,China;Guangzhou,China;Shanghai|
|Japan | Japan;Tokyo|
|USA   | USA;Bostom,USA;New York|

可见有完全相同的效果，且该方法中 **Oracle 11g XE**是可用的。

- 另外，有向XE导入 owmctab.plb  owmaggrs.plb      owmaggrb.plb  重建内置函数的方法

在一些文章中给出了链接，要先下载这几个文件，再执行这些文件
> sql> @owmcatb.plb
   sql>@owmaggrs.plb
   sql>@owmaggrb.plb

现在在网上几乎下载不到这几个文件了，从其它文章看这几个文件应该是从标准版中取出来的，考虑版权的问题，这样用似乎也不妥，而且这几个文件是经过加密的sql，看不到正文，也不要考虑了。

# 最终的选择：
在XE中通过自定义机制增加该方法，如果仅限于一个用户的使用，而且可以不带有wmsys，可以直接在本用户下执行创建类型和function, 就可以了，但如果能这样也就直接改为使用LISTAGG了，所面临的问题的情况是不能修改代码，那就只能采用创建用户wmsys, 在该用户下创建TYPE和Function, 然后再授权给所有人使用。

过程是：
> 1.  创建wmsys用户，并为其授权；
> 2.  以该用户登录；
> 3. 创建TYPE,Function;
> 4. 授权所有人使用

````
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
````

- 代码文件
[Github 下载](https://github.com/wangmengqiang001/blogs/tree/master/wm_concat/src/code.sql)


- 参考文档：
[oracle连接字符串函数，wmsys.wm_concat和LISTAGG](https://blog.csdn.net/qq_33157666/article/details/72854801)
 [Using WMSYS.WM_CONCAT with Oracle XE 10g](https://stackoverflow.com/questions/3513787/using-wmsys-wm-concat-with-oracle-xe-10g)
[Oracle函数之LISTAGG](https://www.cnblogs.com/ivictor/p/4654267.html)
[Oracle列转行函数 Listagg() 语法详解及应用实例](https://blog.csdn.net/hpdlzu80100/article/details/53998413)





