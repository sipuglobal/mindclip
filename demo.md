- 基础业务实体类
    - 用户表
    - 订单表
    - 产品表
    - 客户表
    - 库存表
    - 工单表
    - BOM表
    - 供应商表
    - 采购单表
    - 销售单表
    - 典型特征
        - 一张表代表一个业务实体
        - 字段固定
        - 结构清晰
        - 最符合第三范式

- 层级 / 树结构类
    - 邻接表
        - 写入简单
        - 查询递归复杂
        - 适合层级不深
        - 常见字段
            - id
            - parent_id

    - 闭包表
        - 查询所有祖先、后代、层级很快
        - 适合 BOM、权限、菜单、多级审批
        - 写入复杂、占空间
        - 常见字段
            - ancestor_id
            - descendant_id
            - depth

    - 路径枚举表
        - 查后代很方便
        - 移动节点代价高
        - 适合目录树、文件夹
        - 常见字段
            - id
            - path

    - Nested Set 左右值模型
        - 查询整棵子树很快
        - 插入移动节点很痛苦
        - 适合读多写少
        - 常见字段
            - id
            - lft
            - rgt

    - 图边表
        - 适合复杂网络关系
        - 一个节点可有多个父节点
        - 比树更灵活
        - 常见字段
            - from_id
            - to_id
            - relation_type

- 动态字段类
    - 稀疏表 / EAV 表
        - 非常灵活
        - 适合不同产品字段差异巨大
        - 查询复杂
        - 性能差
        - 很容易变成“万能垃圾表”
        - 常见字段
            - entity_id
            - attr_name
            - attr_value

    - JSON 扩展字段表
        - 比 EAV 更简单
        - 查询能力弱于固定字段
        - 适合非核心扩展字段
        - 常见字段
            - id
            - extra_json

    - 宽表
        - 查询方便
        - 字段冗余
        - NULL 特别多
        - 很适合 BI、报表、搜索索引
        - 常见场景
            - 销售宽表
            - 用户画像宽表
            - BOM展开宽表
            - 库存汇总宽表

    - 扩展表
        - 主表放核心字段
        - 扩展表放低频字段
        - 避免主表字段过多
        - 常见字段
            - entity_id
            - extra_field_xxx

- 配置 / 枚举类
    - 字典表
        - 替代硬编码
        - 方便国际化
        - 方便统一管理
        - 常见字段
            - code
            - name
            - type

    - 配置表
        - 用于系统参数
        - 用于动态开关
        - 用于 feature flag
        - 常见字段
            - config_key
            - config_value

    - 参数表 / 环境变量表
        - 用于运行时参数
        - 常见字段
            - env_key
            - env_value

    - 映射表
        - 用于不同系统之间的值映射
        - 常见场景
            - PDM状态 -> ERP状态
            - ERP物料分类 -> 财务分类
            - 外部编码 -> 内部编码
        - 常见字段
            - source_code
            - target_code

- 分析统计类
    - 事实表
        - 用于记录事件和数值
        - 常见场景
            - 销售事实表
            - 库存变动事实表
            - 工单事实表
        - 常见字段
            - entity_id
            - quantity
            - amount
            - event_time

    - 维度表
        - 用于描述事实表中的属性
        - 常见场景
            - 时间维度
            - 产品维度
            - 客户维度
            - 地区维度

    - 星型模型
        - 一个事实表 + 多个维度表
        - 适合 BI 分析
        - Join 少
        - 查询快

    - 雪花模型
        - 维度继续拆分归一化
        - 更规范
        - Join 更多
        - 适合复杂 BI 模型

    - 汇总表
        - 提前计算好统计结果
        - 常见场景
            - 日销售汇总
            - 月库存汇总
            - 项目进度汇总

- 历史审计类
    - 日志表
        - 记录接口、异常、操作日志
        - 常见字段
            - operator
            - operation
            - create_time

    - 审计表
        - 记录字段变化
        - 常见字段
            - field_name
            - old_value
            - new_value
            - operator

    - 历史表
        - 保存历史版本
        - 常见场景
            - Inventory_History
            - BOM_History
            - Customer_History

    - 快照表
        - 定时保存某一时刻完整状态
        - 常见场景
            - 每日库存快照
            - 每日订单快照
            - 每月财务快照

    - 版本表
        - 用于版本控制
        - 常见字段
            - entity_id
            - version_no
            - status

    - 增量差异表
        - 只记录变化字段
        - 常见字段
            - entity_id
            - version_no
            - field_name
            - old_value
            - new_value

- 高性能 / 缓存类
    - 冗余汇总表
        - 用空间换时间
        - 常见场景
            - BOM展开结果表
            - LLC结果表
            - 库存汇总表

    - 缓存表
        - 保存高频查询结果
        - 常见字段
            - cache_key
            - cache_value
            - expire_time

    - 队列表
        - 用于异步处理
        - 常见场景
            - 同步任务队列
            - 消息发送队列
            - BOM重建队列

    - 临时表
        - 用于导入、中间结果、批处理
        - 常见场景
            - temp_import_data
            - temp_sync_result

    - 中间表
        - 保存复杂流程的阶段性结果
        - 常见场景
            - PDM解析结果
            - ERP接口暂存结果
            - DFS遍历结果

- 多态扩展类
    - 单表继承（STI）
        - 所有类型放一张表
        - 靠 type 字段区分
        - 查询简单
        - NULL 多

    - 类表继承（CTI）
        - 父表 + 子表
        - 结构更规范
        - Join 更多

    - 多态关联表
        - 一张表关联多种对象
        - 常见字段
            - relation_type
            - relation_id
        - 常见场景
            - 评论既可关联订单，也可关联客户，也可关联产品

- 权限与关系类
    - 中间表 / 桥接表
        - 解决多对多关系
        - 常见场景
            - user_role
            - role_permission
            - user_group

    - 权限表
        - 定义权限点
        - 常见字段
            - permission_code
            - permission_name

    - 用户角色表
        - 用户与角色绑定

    - 菜单权限表
        - 菜单与权限绑定

    - 标签关系表
        - 标签与对象绑定
        - 常见场景
            - document_tag
            - product_tag

    - 交叉引用表 / XRef
        - 用于对象间引用关系
        - 常见场景
            - PDM引用关系
            - 文件引用关系
            - BOM引用关系

- 时态与版本类
    - 时态表
        - 自动记录不同时间点的数据状态
        - 常见字段
            - valid_from
            - valid_to

    - Slowly Changing Dimension（SCD）
        - 保留维度变化历史
        - 常见场景
            - 客户地址变化
            - 产品分类变化

    - Anchor Model
        - 极致范式化
        - 支持长期演化和历史追踪
        - 非常复杂
        - 适合大型系统

    - Data Vault
        - Hub
        - Link
        - Satellite
        - 适合多源系统整合
        - 适合数仓