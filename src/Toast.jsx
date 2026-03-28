import { useState, useEffect } from 'react';

export default function Toast({ message, onDone }) {
  const [visible, setVisible] = useState(true);

  useEffect(() => {
    const timer = setTimeout(() => {
      setVisible(false);
      setTimeout(onDone, 300);
    }, 2500);
    return () => clearTimeout(timer);
  }, [onDone]);

  return (
    <div className={`toast ${visible ? 'toast-in' : 'toast-out'}`}>
      {message}
    </div>
  );
}
