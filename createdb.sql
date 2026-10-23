PRAGMA foreign_keys = ON;

--todo : tam, gdzie nie zakladamy mozliwosci usuniecia rekordu dalem restrict,

-- ale dlatego, ze traktowalem te rekordy jako do archiwizacji, a nie usuwania. 
-- jesli jednak umozliwiamy usuwanie, to dobrze by bylo zmienic w przyszlosci


CREATE DOMAIN postal_code AS CHAR(6)
    CHECK (VALUE GLOB '[0-9][0-9]-[0-9][0-9][0-9]');


CREATE TABLE PostalCode (
    id INTEGER PRIMARY KEY,
    code postal_code NOT NULL UNIQUE
);

CREATE TABLE CateringCompany (
    id INTEGER PRIMARY KEY,
    name VARCHAR NOT NULL UNIQUE,
    nip CHAR(10) NOT NULL UNIQUE,
    regon VARCHAR(14) NOT NULL UNIQUE,
    description TEXT NULL,
    contact_email VARCHAR NOT NULL,
    contact_phone VARCHAR NOT NULL,
    verification_status VARCHAR NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_company_nip CHECK (length(nip) = 10 AND nip GLOB '[0-9]*'),
    CONSTRAINT chk_company_regon CHECK (length(regon) IN (9, 14) AND regon GLOB '[0-9]*'),
    CONSTRAINT chk_company_email CHECK (contact_email LIKE '%_@__%.__%'),
    CONSTRAINT chk_company_verification CHECK (verification_status IN ('PENDING', 'VERIFIED', 'REJECTED'))
);

CREATE TABLE Permission (
    id INTEGER PRIMARY KEY,
    code VARCHAR NOT NULL UNIQUE,
    name VARCHAR NOT NULL,
    description VARCHAR NULL,
    CONSTRAINT chk_permission_code_not_empty CHECK (length(trim(code)) > 0)
);

CREATE TABLE Mealtime (
    id INTEGER PRIMARY KEY,
    name VARCHAR NOT NULL UNIQUE,
    display_order INTEGER NOT NULL UNIQUE,
    CONSTRAINT chk_mealtime_order CHECK (display_order > 0)
);

CREATE TABLE Meal (
    id INTEGER PRIMARY KEY,
    name VARCHAR NOT NULL UNIQUE,
    description TEXT NOT NULL,
    weight_grams INTEGER NOT NULL,
    calories_kcal INTEGER NOT NULL,
    protein_g DECIMAL NOT NULL,
    fat_g DECIMAL NOT NULL,
    carbs_g DECIMAL NOT NULL,
    fiber_g DECIMAL NOT NULL,
    salt_g DECIMAL NOT NULL,
    CONSTRAINT chk_meal_weight CHECK (weight_grams > 0),
    CONSTRAINT chk_meal_calories CHECK (calories_kcal >= 0),
    CONSTRAINT chk_meal_macros CHECK (
        protein_g >= 0 AND
        fat_g >= 0 AND
        carbs_g >= 0 AND
        fiber_g >= 0 AND
        salt_g >= 0
    )
);

CREATE TABLE Ingredient (
    id INTEGER PRIMARY KEY,
    name VARCHAR NOT NULL UNIQUE,
    CONSTRAINT chk_ingredient_name CHECK (length(trim(name)) > 0)
);

CREATE TABLE Allergen (
    id INTEGER PRIMARY KEY,
    name VARCHAR NOT NULL UNIQUE,
    description VARCHAR NULL,
    CONSTRAINT chk_allergen_name CHECK (length(trim(name)) > 0)
);

--Users, permissions and addresses

CREATE TABLE "User" (
    id INTEGER PRIMARY KEY,
    catering_company_id INTEGER NULL,
    email VARCHAR NOT NULL UNIQUE,
    password_hash VARCHAR NOT NULL,
    phone_number VARCHAR NOT NULL UNIQUE,
    first_name VARCHAR NOT NULL,
    last_name VARCHAR NOT NULL,
    archived BOOLEAN NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_user_email CHECK (email LIKE '%_@__%.__%'),
    CONSTRAINT chk_user_archived CHECK (archived IN (0, 1)),
    FOREIGN KEY (catering_company_id) REFERENCES CateringCompany(id)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);

CREATE TABLE UserPermission (
    user_id INTEGER NOT NULL,
    permission_id INTEGER NOT NULL,
    PRIMARY KEY (user_id, permission_id),
    FOREIGN KEY (user_id) REFERENCES "User"(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES Permission(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

CREATE TABLE DeliveryAddress (
    id INTEGER PRIMARY KEY,
    postal_code_id INT NOT NULL,
    city VARCHAR NOT NULL,
    street VARCHAR NOT NULL,
    building_number VARCHAR NOT NULL,
    apartment_number VARCHAR NULL,
    floor VARCHAR NULL,
    FOREIGN KEY (postal_code_id) REFERENCES PostalCode(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

CREATE TABLE UserDeliveryAddress (
    user_id INTEGER NOT NULL,
    delivery_address_id INTEGER NOT NULL,
    label VARCHAR NOT NULL,
    is_default BOOLEAN NOT NULL DEFAULT 0,
    PRIMARY KEY (user_id, delivery_address_id),
    CONSTRAINT chk_uda_is_default CHECK (is_default IN (0, 1)),
    FOREIGN KEY (user_id) REFERENCES "User"(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    FOREIGN KEY (delivery_address_id) REFERENCES DeliveryAddress(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

CREATE TABLE BillingData (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    postal_code_id INT NOT NULL,
    buyer_type VARCHAR NOT NULL,
    company_name VARCHAR NULL,
    nip CHAR(10) NULL,
    first_name VARCHAR NULL,
    last_name VARCHAR NULL,
    city VARCHAR NOT NULL,
    street VARCHAR NOT NULL,
    building_number VARCHAR NOT NULL,
    apartment_number VARCHAR NULL,
    CONSTRAINT chk_billing_buyer_type CHECK (buyer_type IN ('PRIVATE', 'COMPANY')),
    CONSTRAINT chk_billing_buyer_details CHECK (
        (buyer_type = 'COMPANY' AND company_name IS NOT NULL AND nip IS NOT NULL AND length(nip) = 10 AND nip GLOB '[0-9]*') OR
        (buyer_type = 'PRIVATE' AND first_name IS NOT NULL AND last_name IS NOT NULL)
    ),
    FOREIGN KEY (user_id) REFERENCES "User"(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    FOREIGN KEY (postal_code_id) REFERENCES PostalCode(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

-- Meals

CREATE TABLE CateringCompanyPostalCode (
    catering_company_id INTEGER NOT NULL,
    postal_code_id INT NOT NULL,
    PRIMARY KEY (catering_company_id, postal_code_id),
    FOREIGN KEY (catering_company_id) REFERENCES CateringCompany(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    FOREIGN KEY (postal_code_id) REFERENCES PostalCode(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

CREATE TABLE DeliveryWindow (
    id INTEGER PRIMARY KEY,
    catering_company_id INTEGER NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    CONSTRAINT chk_delivery_window_times CHECK (start_time < end_time),
    FOREIGN KEY (catering_company_id) REFERENCES CateringCompany(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

CREATE TABLE Diet (
    id INTEGER PRIMARY KEY,
    catering_company_id INTEGER NOT NULL,
    name VARCHAR NOT NULL,
    description TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT 1,
    CONSTRAINT uq_diet_company_name UNIQUE (catering_company_id, name),
    CONSTRAINT chk_diet_is_active CHECK (is_active IN (0, 1)),
    FOREIGN KEY (catering_company_id) REFERENCES CateringCompany(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

CREATE TABLE CaloricVariant (
    id INTEGER PRIMARY KEY,
    diet_id INTEGER NOT NULL,
    calories INTEGER NOT NULL,
    base_price_per_day DECIMAL NOT NULL,
    CONSTRAINT uq_variant_diet_calories UNIQUE (diet_id, calories),
    CONSTRAINT chk_variant_calories CHECK (calories > 0),
    CONSTRAINT chk_variant_price CHECK (base_price_per_day >= 0),
    FOREIGN KEY (diet_id) REFERENCES Diet(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);
-- restrict na slownikowe wystarczy w 99%
CREATE TABLE CaloricVariantMealtime (
    caloric_variant_id INTEGER NOT NULL,
    mealtime_id INTEGER NOT NULL,
    PRIMARY KEY (caloric_variant_id, mealtime_id),
    FOREIGN KEY (caloric_variant_id) REFERENCES CaloricVariant(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    FOREIGN KEY (mealtime_id) REFERENCES Mealtime(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

CREATE TABLE MealMealtime (
    meal_id INTEGER NOT NULL,
    mealtime_id INTEGER NOT NULL,
    PRIMARY KEY (meal_id, mealtime_id),
    FOREIGN KEY (meal_id) REFERENCES Meal(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    FOREIGN KEY (mealtime_id) REFERENCES Mealtime(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

CREATE TABLE MealIngredient (
    meal_id INTEGER NOT NULL,
    ingredient_id INT NOT NULL,
    PRIMARY KEY (meal_id, ingredient_id),
    FOREIGN KEY (meal_id) REFERENCES Meal(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    FOREIGN KEY (ingredient_id) REFERENCES Ingredient(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

CREATE TABLE MealAllergen (
    meal_id INTEGER NOT NULL,
    allergen_id INTEGER NOT NULL,
    PRIMARY KEY (meal_id, allergen_id),
    FOREIGN KEY (meal_id) REFERENCES Meal(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    FOREIGN KEY (allergen_id) REFERENCES Allergen(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

--orders, day plans etc....

CREATE TABLE "Order" (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    delivery_address_id INTEGER NOT NULL,
    delivery_window_id INTEGER NOT NULL,
    status VARCHAR NOT NULL DEFAULT 'NEW',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_order_status CHECK (status IN ('NEW', 'CONFIRMED', 'PAID', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED')),
    FOREIGN KEY (user_id) REFERENCES "User"(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    FOREIGN KEY (delivery_address_id) REFERENCES DeliveryAddress(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    FOREIGN KEY (delivery_window_id) REFERENCES DeliveryWindow(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT --  todo: czy tu realnie musi byc restrict? czy jest to tak wazna informacja?
);

CREATE TABLE OrderItem (
    id INTEGER PRIMARY KEY,
    order_id INTEGER NOT NULL,
    caloric_variant_id INTEGER NOT NULL,
    recipient VARCHAR NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    daily_price_snapshot DECIMAL NOT NULL,
    CONSTRAINT chk_order_item_quantity CHECK (quantity > 0),
    CONSTRAINT chk_order_item_price CHECK (daily_price_snapshot >= 0),
    FOREIGN KEY (order_id) REFERENCES "Order"(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    FOREIGN KEY (caloric_variant_id) REFERENCES CaloricVariant(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

CREATE TABLE DailyPlan (
    id INTEGER PRIMARY KEY,
    order_item_id INTEGER NOT NULL,
    date DATE NOT NULL,
    locked_at TIMESTAMP NOT NULL,
    CONSTRAINT uq_daily_plan_item_date UNIQUE (order_item_id, date),
    FOREIGN KEY (order_item_id) REFERENCES OrderItem(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

CREATE TABLE PlanItem (
    daily_plan_id INTEGER NOT NULL,
    mealtime_id INTEGER NOT NULL,
    meal_id INTEGER NOT NULL,
    PRIMARY KEY (daily_plan_id, mealtime_id),
    FOREIGN KEY (daily_plan_id) REFERENCES DailyPlan(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    FOREIGN KEY (mealtime_id) REFERENCES Mealtime(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    FOREIGN KEY (meal_id) REFERENCES Meal(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

CREATE TABLE Delivery (
    id INTEGER PRIMARY KEY,
    order_id INTEGER NOT NULL,
    scheduled_date DATE NOT NULL,
    delivered_at TIMESTAMP NULL,
    status VARCHAR NOT NULL DEFAULT 'PLANNED',
    CONSTRAINT chk_delivery_status CHECK (status IN ('PLANNED', 'IN_TRANSIT', 'DELIVERED', 'FAILED', 'CANCELLED')),
    FOREIGN KEY (order_id) REFERENCES "Order"(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

CREATE TABLE DeliveryDailyPlan (
    delivery_id INTEGER NOT NULL,
    daily_plan_id INTEGER NOT NULL,
    PRIMARY KEY (delivery_id, daily_plan_id),
    FOREIGN KEY (delivery_id) REFERENCES Delivery(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    FOREIGN KEY (daily_plan_id) REFERENCES DailyPlan(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

CREATE TABLE Billing (
    id INTEGER PRIMARY KEY,
    order_id INTEGER NOT NULL UNIQUE,
    billing_data_id INTEGER NULL,
    document_type VARCHAR NOT NULL,
    document_number VARCHAR NULL UNIQUE,
    amount DECIMAL NOT NULL,
    paid_at TIMESTAMP NULL,
    CONSTRAINT chk_billing_doc_type CHECK (document_type IN ('RECEIPT', 'INVOICE')),
    CONSTRAINT chk_billing_amount CHECK (amount >= 0),
    FOREIGN KEY (order_id) REFERENCES "Order"(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    FOREIGN KEY (billing_data_id) REFERENCES BillingData(id)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);

-- Reviews, complaints


CREATE TABLE Review (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    catering_company_id INTEGER NOT NULL,
    delivery_id INTEGER NOT NULL,
    meal_id INTEGER NULL,
    rating INTEGER NOT NULL,
    comment TEXT NULL,
    moderation_status VARCHAR NOT NULL DEFAULT 'VISIBLE',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_review_rating CHECK (rating BETWEEN 1 AND 5),
    CONSTRAINT chk_review_mod_status CHECK (moderation_status IN ('PENDING', 'VISIBLE', 'HIDDEN')),
    FOREIGN KEY (user_id) REFERENCES "User"(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    FOREIGN KEY (catering_company_id) REFERENCES CateringCompany(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    FOREIGN KEY (delivery_id) REFERENCES Delivery(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    FOREIGN KEY (meal_id) REFERENCES Meal(id)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);


-- trzeba archiwizowac konta moderatorow, nie usuwac - to jest jakby okej, choc w teorii jesli jest zamkniety ticket to mozna by nullowac
CREATE TABLE ModerationLog (
    id INTEGER PRIMARY KEY,
    review_id INTEGER NOT NULL UNIQUE,
    user_id INTEGER NOT NULL,
    moderation_note VARCHAR NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_mod_note_not_empty CHECK (length(trim(moderation_note)) > 0),
    FOREIGN KEY (review_id) REFERENCES Review(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES "User"(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

CREATE TABLE Complaint (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    order_id INTEGER NOT NULL,
    delivery_id INTEGER NULL UNIQUE,
    subject VARCHAR NOT NULL,
    description TEXT NOT NULL,
    status VARCHAR NOT NULL DEFAULT 'OPEN',
    decision_justification TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP NULL,
    CONSTRAINT chk_complaint_status CHECK (status IN ('OPEN', 'IN_PROGRESS', 'RESOLVED', 'REJECTED')),
    CONSTRAINT chk_complaint_dates CHECK (resolved_at IS NULL OR resolved_at >= created_at),
    FOREIGN KEY (user_id) REFERENCES "User"(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    FOREIGN KEY (order_id) REFERENCES "Order"(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT ,--todo: ja bym nie dawal cascade, ale usuniecie order'u to sytuacja, o ktorej nie myslelismy albo ja przegapilem - zakladam, ze jest nierealna
    FOREIGN KEY (delivery_id) REFERENCES Delivery(id)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);