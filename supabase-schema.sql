-- Schema untuk sistem checkout dan transaksi di Supabase

-- Tabel untuk menyimpan data pesanan
CREATE TABLE IF NOT EXISTS orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_number VARCHAR(50) NOT NULL UNIQUE,
    user_id UUID NOT NULL REFERENCES auth.users(id),
    status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'processing', 'completed', 'cancelled', 'refunded')),
    shipping_address JSONB NOT NULL,
    payment_method VARCHAR(50) NOT NULL,
    subtotal INTEGER NOT NULL,
    shipping_cost INTEGER NOT NULL,
    tax INTEGER NOT NULL,
    total_amount INTEGER NOT NULL,
    payment_details JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indeks untuk mempercepat pencarian berdasarkan user_id dan status
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at);

-- Tabel untuk menyimpan item pesanan
CREATE TABLE IF NOT EXISTS order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    price INTEGER NOT NULL,
    subtotal INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indeks untuk mempercepat pencarian berdasarkan order_id dan product_id
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product_id ON order_items(product_id);

-- Tabel untuk menyimpan riwayat pembayaran
CREATE TABLE IF NOT EXISTS payment_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    payment_method VARCHAR(50) NOT NULL,
    amount INTEGER NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'success', 'failed', 'refunded')),
    payment_details JSONB,
    transaction_id VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indeks untuk mempercepat pencarian berdasarkan order_id dan status
CREATE INDEX IF NOT EXISTS idx_payment_history_order_id ON payment_history(order_id);
CREATE INDEX IF NOT EXISTS idx_payment_history_status ON payment_history(status);

-- Tabel untuk menyimpan riwayat pengiriman
CREATE TABLE IF NOT EXISTS shipping_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'returned')),
    tracking_number VARCHAR(100),
    shipping_method VARCHAR(50),
    shipping_details JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indeks untuk mempercepat pencarian berdasarkan order_id dan status
CREATE INDEX IF NOT EXISTS idx_shipping_history_order_id ON shipping_history(order_id);
CREATE INDEX IF NOT EXISTS idx_shipping_history_status ON shipping_history(status);

-- Fungsi untuk memperbarui updated_at secara otomatis
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger untuk memperbarui updated_at pada tabel orders
CREATE TRIGGER update_orders_updated_at
BEFORE UPDATE ON orders
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Trigger untuk memperbarui updated_at pada tabel payment_history
CREATE TRIGGER update_payment_history_updated_at
BEFORE UPDATE ON payment_history
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Trigger untuk memperbarui updated_at pada tabel shipping_history
CREATE TRIGGER update_shipping_history_updated_at
BEFORE UPDATE ON shipping_history
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Fungsi untuk mengurangi stok produk setelah pesanan dibuat
CREATE OR REPLACE FUNCTION decrease_product_stock()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE products
    SET stock = products.stock - NEW.quantity
    WHERE id = NEW.product_id AND products.stock >= NEW.quantity;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Stok produk tidak mencukupi';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger untuk mengurangi stok produk setelah item pesanan ditambahkan
CREATE TRIGGER decrease_stock_after_order
AFTER INSERT ON order_items
FOR EACH ROW
EXECUTE FUNCTION decrease_product_stock();

-- Kebijakan keamanan Row Level Security (RLS)

-- Aktifkan RLS pada tabel orders
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- Kebijakan untuk tabel orders
CREATE POLICY "Users can view their own orders" ON orders
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own orders" ON orders
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own orders" ON orders
    FOR UPDATE
    USING (auth.uid() = user_id);

-- Aktifkan RLS pada tabel order_items
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

-- Kebijakan untuk tabel order_items
CREATE POLICY "Users can view their own order items" ON order_items
    FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM orders
        WHERE orders.id = order_items.order_id
        AND orders.user_id = auth.uid()
    ));

CREATE POLICY "Users can insert their own order items" ON order_items
    FOR INSERT
    WITH CHECK (EXISTS (
        SELECT 1 FROM orders
        WHERE orders.id = order_items.order_id
        AND orders.user_id = auth.uid()
    ));

-- Aktifkan RLS pada tabel payment_history
ALTER TABLE payment_history ENABLE ROW LEVEL SECURITY;

-- Kebijakan untuk tabel payment_history
CREATE POLICY "Users can view their own payment history" ON payment_history
    FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM orders
        WHERE orders.id = payment_history.order_id
        AND orders.user_id = auth.uid()
    ));

CREATE POLICY "Users can insert their own payment history" ON payment_history
    FOR INSERT
    WITH CHECK (EXISTS (
        SELECT 1 FROM orders
        WHERE orders.id = payment_history.order_id
        AND orders.user_id = auth.uid()
    ));

CREATE POLICY "Service role can insert payment history" ON payment_history
    FOR INSERT
    TO service_role
    WITH CHECK (true);

-- Aktifkan RLS pada tabel shipping_history
ALTER TABLE shipping_history ENABLE ROW LEVEL SECURITY;

-- Kebijakan untuk tabel shipping_history
CREATE POLICY "Users can view their own shipping history" ON shipping_history
    FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM orders
        WHERE orders.id = shipping_history.order_id
        AND orders.user_id = auth.uid()
    ));

-- Tabel untuk menyimpan keranjang belanja
CREATE TABLE IF NOT EXISTS cart (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indeks untuk mempercepat pencarian berdasarkan user_id
CREATE INDEX IF NOT EXISTS idx_cart_user_id ON cart(user_id);

-- Tabel untuk menyimpan item dalam keranjang belanja
CREATE TABLE IF NOT EXISTS cart_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cart_id UUID NOT NULL REFERENCES cart(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(cart_id, product_id)
);

-- Indeks untuk mempercepat pencarian berdasarkan cart_id dan product_id
CREATE INDEX IF NOT EXISTS idx_cart_items_cart_id ON cart_items(cart_id);
CREATE INDEX IF NOT EXISTS idx_cart_items_product_id ON cart_items(product_id);

-- Trigger untuk memperbarui updated_at pada tabel cart
CREATE TRIGGER update_cart_updated_at
BEFORE UPDATE ON cart
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Trigger untuk memperbarui updated_at pada tabel cart_items
CREATE TRIGGER update_cart_items_updated_at
BEFORE UPDATE ON cart_items
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Aktifkan RLS pada tabel cart
ALTER TABLE cart ENABLE ROW LEVEL SECURITY;

-- Kebijakan untuk tabel cart
CREATE POLICY "Users can view their own cart" ON cart
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own cart" ON cart
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own cart" ON cart
    FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own cart" ON cart
    FOR DELETE
    USING (auth.uid() = user_id);

-- Aktifkan RLS pada tabel cart_items
ALTER TABLE cart_items ENABLE ROW LEVEL SECURITY;

-- Kebijakan untuk tabel cart_items
CREATE POLICY "Users can view their own cart items" ON cart_items
    FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM cart
        WHERE cart.id = cart_items.cart_id
        AND cart.user_id = auth.uid()
    ));

CREATE POLICY "Users can insert their own cart items" ON cart_items
    FOR INSERT
    WITH CHECK (EXISTS (
        SELECT 1 FROM cart
        WHERE cart.id = cart_items.cart_id
        AND cart.user_id = auth.uid()
    ));

CREATE POLICY "Users can update their own cart items" ON cart_items
    FOR UPDATE
    USING (EXISTS (
        SELECT 1 FROM cart
        WHERE cart.id = cart_items.cart_id
        AND cart.user_id = auth.uid()
    ));

CREATE POLICY "Users can delete their own cart items" ON cart_items
    FOR DELETE
    USING (EXISTS (
        SELECT 1 FROM cart
        WHERE cart.id = cart_items.cart_id
        AND cart.user_id = auth.uid()
    ));

-- Berikan akses ke anon dan authenticated roles
GRANT SELECT, INSERT, UPDATE ON orders TO anon, authenticated;
GRANT SELECT, INSERT ON order_items TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE ON payment_history TO anon, authenticated;
GRANT SELECT ON shipping_history TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON cart TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON cart_items TO anon, authenticated;

-- Berikan akses ke sequence
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;