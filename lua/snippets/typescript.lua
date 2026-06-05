local ls = require("luasnip")
local s = ls.snippet
local i = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt

return {

  -- ====================
  -- MODULES
  -- ====================

  s("nestmodule", fmt([[
import {{ Module }} from "@nestjs/common";

@Module({{
  imports: [{}],
  controllers: [{}],
  providers: [{}],
  exports: [{}],
}})
export class {}Module {{}}
]], {
    i(1),
    i(2),
    i(3),
    i(4),
    i(5, "Users"),
  })),

  -- ====================
  -- CONTROLLERS
  -- ====================

  s("nestcontroller", fmt([[
import {{ Controller, Get }} from "@nestjs/common";
import {{ {}Service }} from "./{}.service";

@Controller("{}")
export class {}Controller {{
  constructor(
    private readonly service: {}Service,
  ) {{}}

  @Get()
  findAll() {{
    return this.service.findAll();
  }}
}}
]], {
    i(1, "Users"),
    i(2, "users"),
    i(3, "users"),
    i(4, "Users"),
    i(5, "Users"),
  })),

  s("crudcontroller", fmt([[
@Get()
findAll() {{
  {}
}}

@Get(":id")
findOne(@Param("id") id: string) {{
  {}
}}

@Post()
create(@Body() dto: Create{}Dto) {{
  {}
}}

@Patch(":id")
update(
  @Param("id") id: string,
  @Body() dto: Update{}Dto,
) {{
  {}
}}

@Delete(":id")
remove(@Param("id") id: string) {{
  {}
}}
]], {
    i(1),
    i(2),
    i(3, "User"),
    i(4),
    i(5, "User"),
    i(6),
    i(7),
  })),

  -- ====================
  -- SERVICES
  -- ====================

  s("nestservice", fmt([[
import {{ Injectable }} from "@nestjs/common";

@Injectable()
export class {}Service {{
  findAll() {{
    return [];
  }}

  findOne(id: string) {{
    return {{ id }};
  }}

  create(dto: any) {{
    return dto;
  }}

  update(id: string, dto: any) {{
    return {{ id, ...dto }};
  }}

  remove(id: string) {{
    return {{ deleted: id }};
  }}
}}
]], {
    i(1, "Users"),
  })),

  s("serviceinject", fmt([[
constructor(
  private readonly {}: {}Service,
) {{}}
]], {
    i(1, "usersService"),
    i(2, "Users"),
  })),

  -- ====================
  -- DTOs
  -- ====================

  s("dto", fmt([[
import {{ IsString }} from "class-validator";

export class {}Dto {{
  @IsString()
  {}: string;
}}
]], {
    i(1, "CreateUser"),
    i(2, "name"),
  })),

  s("dtofull", fmt([[
import {{
  IsString,
  IsEmail,
  IsOptional,
}} from "class-validator";

export class {}Dto {{
  @IsString()
  name: string;

  @IsEmail()
  email: string;

  @IsOptional()
  @IsString()
  bio?: string;
}}
]], {
    i(1, "CreateUser"),
  })),

  -- ====================
  -- GUARDS
  -- ====================

  s("guard", fmt([[
import {{
  CanActivate,
  ExecutionContext,
  Injectable,
}} from "@nestjs/common";

@Injectable()
export class {}Guard implements CanActivate {{
  canActivate(
    context: ExecutionContext,
  ): boolean {{
    return true;
  }}
}}
]], {
    i(1, "Auth"),
  })),

  s("useguard", fmt([[
@UseGuards({}Guard)
]], {
    i(1, "Auth"),
  })),

  -- ====================
  -- PIPES
  -- ====================

  s("pipe", fmt([[
import {{
  Injectable,
  PipeTransform,
}} from "@nestjs/common";

@Injectable()
export class {}Pipe
  implements PipeTransform
{{
  transform(value: any) {{
    return value;
  }}
}}
]], {
    i(1, "Validation"),
  })),

  -- ====================
  -- INTERCEPTORS
  -- ====================

  s("interceptor", fmt([[
import {{
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
}} from "@nestjs/common";

@Injectable()
export class {}Interceptor
  implements NestInterceptor
{{
  intercept(
    context: ExecutionContext,
    next: CallHandler,
  ) {{
    return next.handle();
  }}
}}
]], {
    i(1, "Logging"),
  })),

  s("useinterceptor", fmt([[
@UseInterceptors({}Interceptor)
]], {
    i(1, "Logging"),
  })),

  -- ====================
  -- FILTERS
  -- ====================

  s("filter", fmt([[
import {{
  Catch,
  ExceptionFilter,
  ArgumentsHost,
  HttpException,
}} from "@nestjs/common";

@Catch(HttpException)
export class {}Filter
  implements ExceptionFilter
{{
  catch(
    exception: HttpException,
    host: ArgumentsHost,
  ) {{
    const ctx = host.switchToHttp();
    const response = ctx.getResponse();

    response.status(
      exception.getStatus(),
    ).json({{
      message: exception.message,
    }});
  }}
}}
]], {
    i(1, "Http"),
  })),

  s("usefilter", fmt([[
@UseFilters({}Filter)
]], {
    i(1, "Http"),
  })),

  -- ====================
  -- MIDDLEWARE
  -- ====================

  s("middleware", fmt([[
import {{
  Injectable,
  NestMiddleware,
}} from "@nestjs/common";

@Injectable()
export class {}Middleware
  implements NestMiddleware
{{
  use(req, res, next) {{
    next();
  }}
}}
]], {
    i(1, "Logger"),
  })),

  -- ====================
  -- DECORATORS
  -- ====================

  s("decorator", fmt([[
import {{
  createParamDecorator,
  ExecutionContext,
}} from "@nestjs/common";

export const {} =
  createParamDecorator(
    (data: unknown, ctx: ExecutionContext) => {{
      const req =
        ctx.switchToHttp().getRequest();

      return req.user;
    }},
  );
]], {
    i(1, "User"),
  })),

  -- ====================
  -- TYPEORM
  -- ====================

  s("entity", fmt([[
import {{
  Entity,
  PrimaryGeneratedColumn,
  Column,
}} from "typeorm";

@Entity()
export class {} {{
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  name: string;
}}
]], {
    i(1, "User"),
  })),

  s("injectrepo", fmt([[
constructor(
  @InjectRepository({})
  private readonly repo:
    Repository<{}>,
) {{}}
]], {
    i(1, "User"),
    i(2, "User"),
  })),

  -- ====================
  -- SWAGGER
  -- ====================

  s("swaggercontroller", fmt([[
@ApiTags("{}")
@Controller("{}")
export class {}Controller {{}}
]], {
    i(1, "users"),
    i(2, "users"),
    i(3, "Users"),
  })),

  s("swaggerprop", fmt([[
@ApiProperty()
{}: {};
]], {
    i(1, "name"),
    i(2, "string"),
  })),

  -- ====================
  -- ROUTES
  -- ====================

  s("get", fmt([[
@Get("{}")
{}() {{
  {}
}}
]], {
    i(1),
    i(2, "findAll"),
    i(3),
  })),

  s("post", fmt([[
@Post("{}")
{}() {{
  {}
}}
]], {
    i(1),
    i(2, "create"),
    i(3),
  })),

  s("patch", fmt([[
@Patch(":id")
{}(
  @Param("id") id: string,
) {{
  {}
}}
]], {
    i(1, "update"),
    i(2),
  })),

  s("delete", fmt([[
@Delete(":id")
{}(
  @Param("id") id: string,
) {{
  {}
}}
]], {
    i(1, "remove"),
    i(2),
  })),

  -- ====================
  -- PARAMS
  -- ====================

  s("body", fmt([[
@Body() dto: {}
]], {
    i(1, "CreateUserDto"),
  })),

  s("param", fmt([[
@Param("{}") {}: string
]], {
    i(1, "id"),
    i(2, "id"),
  })),

  s("query", fmt([[
@Query("{}") {}: string
]], {
    i(1),
    i(2),
  })),

  -- ====================
  -- TESTING
  -- ====================

  s("specservice", fmt([[
describe("{}", () => {{
  let service: {};

  beforeEach(async () => {{
  }});

  it("should be defined", () => {{
    expect(service).toBeDefined();
  }});
}});
]], {
    i(1, "UsersService"),
    i(2, "UsersService"),
  })),

  s("speccontroller", fmt([[
describe("{}", () => {{
  let controller: {};

  beforeEach(async () => {{
  }});

  it("should be defined", () => {{
    expect(controller).toBeDefined();
  }});
}});
]], {
    i(1, "UsersController"),
    i(2, "UsersController"),
  })),

  -- ==========================================
  -- ENTITY
  -- ==========================================

  s("mientity", fmt([[
import {{
  Entity,
  PrimaryKey,
  Property,
}} from "@mikro-orm/core";

@Entity()
export class {} {{
  @PrimaryKey()
  id!: number;

  @Property()
  {}!: string;
}}
]], {
    i(1, "User"),
    i(2, "name"),
  })),

  -- ==========================================
  -- MANY TO ONE
  -- ==========================================

  s("mim2o", fmt([[
@ManyToOne(() => {})
{}!: {};
]], {
    i(1, "User"),
    i(2, "user"),
    i(3, "User"),
  })),

  -- ==========================================
  -- ONE TO MANY
  -- ==========================================

  s("mio2m", fmt([[
@OneToMany(
  () => {},
  {} => {}.{},
)
{} = new Collection<{}>(this);
]], {
    i(1, "Post"),
    i(2, "post"),
    i(3, "post"),
    i(4, "author"),
    i(5, "posts"),
    i(6, "Post"),
  })),

  -- ==========================================
  -- MANY TO MANY
  -- ==========================================

  s("mim2m", fmt([[
@ManyToMany(() => {})
{} = new Collection<{}>(this);
]], {
    i(1, "Role"),
    i(2, "roles"),
    i(3, "Role"),
  })),

  -- ==========================================
  -- ONE TO ONE
  -- ==========================================

  s("mio2o", fmt([[
@OneToOne(() => {})
{}!: {};
]], {
    i(1, "Profile"),
    i(2, "profile"),
    i(3, "Profile"),
  })),

  -- ==========================================
  -- COLLECTION
  -- ==========================================

  s("micollection", fmt([[
{} = new Collection<{}>(this);
]], {
    i(1, "posts"),
    i(2, "Post"),
  })),

  -- ==========================================
  -- ENTITY MANAGER INJECTION
  -- ==========================================

  s("miem", fmt([[
constructor(
  private readonly em: EntityManager,
) {{}}
]], {})),

  -- ==========================================
  -- REPOSITORY INJECTION
  -- ==========================================

  s("mirepo", fmt([[
constructor(
  @InjectRepository({})
  private readonly repo:
    EntityRepository<{}>,
) {{}}
]], {
    i(1, "User"),
    i(2, "User"),
  })),

  -- ==========================================
  -- FIND ALL
  -- ==========================================

  s("mifindall", fmt([[
const {} =
  await this.repo.findAll();
]], {
    i(1, "users"),
  })),

  -- ==========================================
  -- FIND ONE
  -- ==========================================

  s("mifindone", fmt([[
const {} =
  await this.repo.findOne({{
    {}: {},
  }});
]], {
    i(1, "user"),
    i(2, "id"),
    i(3, "id"),
  })),

  -- ==========================================
  -- CREATE
  -- ==========================================

  s("micreate", fmt([[
const entity =
  this.repo.create({{
    {}
  }});

await this.em.persistAndFlush(
  entity,
);
]], {
    i(1),
  })),

  -- ==========================================
  -- PERSIST
  -- ==========================================

  s("mipersist", fmt([[
await this.em.persistAndFlush(
  {},
);
]], {
    i(1, "entity"),
  })),

  -- ==========================================
  -- REMOVE
  -- ==========================================

  s("miremove", fmt([[
await this.em.removeAndFlush(
  {},
);
]], {
    i(1, "entity"),
  })),

  -- ==========================================
  -- TRANSACTION
  -- ==========================================

  s("mitx", fmt([[
await this.em.transactional(
  async em => {{
    {}
  }},
);
]], {
    i(1),
  })),

  -- ==========================================
  -- POPULATE
  -- ==========================================

  s("mipopulate", fmt([[
const {} =
  await this.repo.find(
    {{}},
    {{
      populate: ["{}"],
    }},
  );
]], {
    i(1, "users"),
    i(2, "posts"),
  })),

  -- ==========================================
  -- REQUEST CONTEXT
  -- ==========================================

  s("mirc", fmt([[
RequestContext.create(
  this.orm.em,
  async () => {{
    {}
  }},
);
]], {
    i(1),
  })),

  -- ==========================================
  -- FILTER
  -- ==========================================

  s("mifilter", fmt([[
@Filter({{
  name: "{}",
  cond: () => ({{
    deletedAt: null,
  }}),
}})
]], {
    i(1, "notDeleted"),
  })),

  -- ==========================================
  -- EMBEDDABLE
  -- ==========================================

  s("miembeddable", fmt([[
import {{
  Embeddable,
  Property,
}} from "@mikro-orm/core";

@Embeddable()
export class {} {{
  @Property()
  {}!: string;
}}
]], {
    i(1, "Address"),
    i(2, "street"),
  })),

  -- ==========================================
  -- EMBEDDED
  -- ==========================================

  s("miembedded", fmt([[
@Embedded(() => {})
{}!: {};
]], {
    i(1, "Address"),
    i(2, "address"),
    i(3, "Address"),
  })),

  -- ==========================================
  -- SOFT DELETE FIELD
  -- ==========================================

  s("misoftdelete", fmt([[
@Property({{
  nullable: true,
}})
deletedAt?: Date;
]], {})),

  -- ==========================================
  -- CREATED AT
  -- ==========================================

  s("micreated", fmt([[
@Property()
createdAt = new Date();
]], {})),

  -- ==========================================
  -- UPDATED AT
  -- ==========================================

  s("miupdated", fmt([[
@Property({{
  onUpdate: () => new Date(),
}})
updatedAt = new Date();
]], {})),

  -- ==========================================
  -- NESTJS SERVICE
  -- ==========================================

  s("miservice", fmt([[
@Injectable()
export class {}Service {{
  constructor(
    @InjectRepository({})
    private readonly repo:
      EntityRepository<{}>,
    private readonly em:
      EntityManager,
  ) {{}}
}}
]], {
    i(1, "Users"),
    i(2, "User"),
    i(3, "User"),
  })),

}
